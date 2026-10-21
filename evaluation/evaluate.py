"""text2RLS evaluation script.

Computes metrics for model predictions against gold standard:
1. Policy Creation Success (PCS)
2. RLS Component Accuracy
3. Predicate Atom F1
4. Attribute Grounding F1

Usage:
    python3 evaluation/evaluate.py \
        --predictions_path outputs/codet5p-770m/predictions.json \
        --output_path results/codet5p-770m_results.json
"""

import argparse
import json
import logging
import re
from collections import defaultdict
from typing import Dict, List, Optional, Set, Tuple, Any

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# SQL Parsing Helpers
# ---------------------------------------------------------------------------

def normalize_sql(sql: str) -> str:
    """Normalize SQL whitespace and casing for comparison."""
    sql = re.sub(r'\s+', ' ', sql.strip())
    return sql


def extract_create_policies(sql: str) -> List[str]:
    """Extract individual CREATE POLICY statements from SQL text.

    Args:
        sql: SQL text that may contain one or more CREATE POLICY statements.

    Returns:
        List of individual CREATE POLICY statements.
    """
    if not sql or not sql.strip():
        return []

    # Try to split on CREATE POLICY boundaries
    parts = re.split(r'(?=CREATE\s+POLICY\b)', sql, flags=re.IGNORECASE)
    policies = []
    for part in parts:
        part = part.strip()
        if re.match(r'CREATE\s+POLICY\b', part, re.IGNORECASE):
            # Clean up trailing garbage after semicolon
            semi_idx = part.rfind(';')
            if semi_idx != -1:
                part = part[:semi_idx + 1]
            policies.append(part)

    return policies


def parse_policy_components(sql: str) -> Optional[Dict[str, Any]]:
    """Parse a single CREATE POLICY statement into its components.

    Args:
        sql: A single CREATE POLICY statement.

    Returns:
        Dict with keys: policy_name, target_table, operation, to_role,
        has_using, has_with_check, mode (permissive/restrictive),
        using_clause, with_check_clause.
        None if parsing fails entirely.
    """
    sql_norm = normalize_sql(sql)

    result = {
        "policy_name": None,
        "target_table": None,
        "operation": None,
        "to_role": None,
        "has_using": False,
        "has_with_check": False,
        "mode": "PERMISSIVE",  # default
        "using_clause": None,
        "with_check_clause": None,
    }

    # Policy name
    name_m = re.search(
        r'CREATE\s+POLICY\s+(\S+)',
        sql_norm, re.IGNORECASE,
    )
    if name_m:
        result["policy_name"] = name_m.group(1).strip('"').lower()

    # Target table (ON clause)
    on_m = re.search(
        r'\bON\s+(\w+\.\w+)',
        sql_norm, re.IGNORECASE,
    )
    if on_m:
        result["target_table"] = on_m.group(1).lower()

    # Operation (FOR clause)
    for_m = re.search(
        r'\bFOR\s+(SELECT|INSERT|UPDATE|DELETE|ALL)\b',
        sql_norm, re.IGNORECASE,
    )
    if for_m:
        result["operation"] = for_m.group(1).upper()

    # TO role
    to_m = re.search(
        r'\bTO\s+(\w+)',
        sql_norm, re.IGNORECASE,
    )
    if to_m:
        role = to_m.group(1).lower()
        if role not in ('using', 'as', 'with'):
            result["to_role"] = role

    # Mode
    if re.search(r'\bAS\s+RESTRICTIVE\b', sql_norm, re.IGNORECASE):
        result["mode"] = "RESTRICTIVE"

    # USING clause
    if re.search(r'\bUSING\s*\(', sql_norm, re.IGNORECASE):
        result["has_using"] = True
        result["using_clause"] = _extract_clause(sql_norm, "USING")

    # WITH CHECK clause
    if re.search(r'\bWITH\s+CHECK\s*\(', sql_norm, re.IGNORECASE):
        result["has_with_check"] = True
        result["with_check_clause"] = _extract_clause(sql_norm, "WITH CHECK")

    return result


def _extract_clause(sql: str, clause_type: str) -> Optional[str]:
    """Extract the content of a USING or WITH CHECK clause.

    Handles nested parentheses.

    Args:
        sql: Normalized SQL string.
        clause_type: 'USING' or 'WITH CHECK'.

    Returns:
        The clause content (inside outer parens), or None.
    """
    if clause_type == "WITH CHECK":
        pattern = r'\bWITH\s+CHECK\s*\('
    else:
        pattern = r'\bUSING\s*\('

    m = re.search(pattern, sql, re.IGNORECASE)
    if not m:
        return None

    start = m.end() - 1  # position of opening paren
    depth = 0
    end = start
    for i in range(start, len(sql)):
        if sql[i] == '(':
            depth += 1
        elif sql[i] == ')':
            depth -= 1
            if depth == 0:
                end = i
                break

    if depth != 0:
        return None

    return sql[start + 1:end].strip()


# ---------------------------------------------------------------------------
# Predicate Atom Extraction
# ---------------------------------------------------------------------------

def extract_predicate_atoms(clause: Optional[str]) -> Set[str]:
    """Split a USING/WITH CHECK clause into predicate atoms.

    Splits on AND/OR at the top level (not inside parentheses).
    Normalizes whitespace and lowercases for comparison.

    Args:
        clause: The clause content string.

    Returns:
        Set of normalized predicate atom strings.
    """
    if not clause:
        return set()

    # Split on top-level AND/OR
    atoms = _split_top_level(clause)

    # Normalize each atom
    normalized = set()
    for atom in atoms:
        atom = atom.strip()
        if not atom:
            continue
        # Remove outer parentheses
        while atom.startswith('(') and atom.endswith(')'):
            inner = atom[1:-1]
            # Check balanced
            depth = 0
            balanced = True
            for c in inner:
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
                    if depth < 0:
                        balanced = False
                        break
            if balanced and depth == 0:
                atom = inner.strip()
            else:
                break

        # Normalize whitespace and case
        atom = re.sub(r'\s+', ' ', atom).strip().lower()
        if atom:
            normalized.add(atom)

    return normalized


def _split_top_level(clause: str) -> List[str]:
    """Split clause on top-level AND/OR keywords.

    Args:
        clause: SQL clause string.

    Returns:
        List of atom strings.
    """
    parts = []
    depth = 0
    current = []
    tokens = re.split(r'(\s+AND\s+|\s+OR\s+)', clause, flags=re.IGNORECASE)

    i = 0
    while i < len(tokens):
        token = tokens[i]
        # Count parens
        for c in token:
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1

        if depth == 0 and re.match(r'\s+(AND|OR)\s+', token, re.IGNORECASE):
            parts.append(''.join(current))
            current = []
        else:
            current.append(token)
        i += 1

    if current:
        parts.append(''.join(current))

    return parts


# ---------------------------------------------------------------------------
# Attribute Extraction
# ---------------------------------------------------------------------------

def extract_attributes_from_sql(sql: str) -> Dict[str, Set[str]]:
    """Extract ABAC attributes from a CREATE POLICY SQL.

    Args:
        sql: CREATE POLICY SQL string.

    Returns:
        Dict with keys 's_attributes', 'o_attributes', 'e_attributes',
        each mapping to a set of attribute names.
    """
    s_attrs = set()
    o_attrs = set()
    e_attrs = set()

    # Subject attributes: current_setting('app.xxx', true)
    for m in re.finditer(
        r"current_setting\s*\(\s*'(app\.\w+)'\s*,\s*true\s*\)",
        sql, re.IGNORECASE,
    ):
        s_attrs.add(m.group(1).lower())

    # Environment attributes: CURRENT_TIMESTAMP, CURRENT_DATE, etc.
    env_patterns = [
        (r'\bCURRENT_TIMESTAMP\b', 'current_timestamp'),
        (r'\bCURRENT_DATE\b', 'current_date'),
        (r'\bCURRENT_TIME\b', 'current_time'),
        (r'\bNOW\s*\(\s*\)', 'now()'),
        (r'\bLOCALTIMESTAMP\b', 'localtimestamp'),
    ]
    for pattern, name in env_patterns:
        if re.search(pattern, sql, re.IGNORECASE):
            e_attrs.add(name)

    # Object attributes: column references in USING/WITH CHECK
    # These are columns from the target table used in conditions
    # Extract from parsed clause
    policies = extract_create_policies(sql)
    for policy_sql in policies:
        comp = parse_policy_components(policy_sql)
        if comp and comp["target_table"]:
            table = comp["target_table"]
            # Extract column-like references from USING and WITH CHECK
            for clause in [comp["using_clause"], comp["with_check_clause"]]:
                if clause:
                    # Match bare column names (not prefixed with app. or schema.)
                    # These are typically object attributes
                    for col_m in re.finditer(r'\b(\w+)\b', clause):
                        col = col_m.group(1).lower()
                        # Filter out SQL keywords and functions
                        if col in _SQL_KEYWORDS:
                            continue
                        if col.startswith('app_'):
                            continue
                        o_attrs.add(col)

    return {
        "s_attributes": s_attrs,
        "o_attributes": o_attrs,
        "e_attributes": e_attrs,
    }


_SQL_KEYWORDS = {
    'select', 'from', 'where', 'and', 'or', 'not', 'in', 'is',
    'null', 'true', 'false', 'exists', 'between', 'like', 'ilike',
    'case', 'when', 'then', 'else', 'end', 'as', 'on', 'join',
    'left', 'right', 'inner', 'outer', 'cross', 'using', 'with',
    'check', 'create', 'policy', 'for', 'to', 'all', 'insert',
    'update', 'delete', 'grant', 'public', 'current_setting',
    'current_timestamp', 'current_date', 'current_time', 'now',
    'interval', 'cast', 'int', 'integer', 'text', 'boolean',
    'varchar', 'timestamp', 'date', 'numeric', 'float', 'double',
    'precision', 'coalesce', 'nullif', 'distinct', 'any', 'some',
    'having', 'group', 'by', 'order', 'asc', 'desc', 'limit',
    'offset', 'union', 'intersect', 'except', 'primary', 'key',
    'foreign', 'references', 'default', 'constraint', 'unique',
    'index', 'table', 'column', 'alter', 'add', 'drop', 'type',
    'enum', 'set', 'restrictive', 'permissive', 'localtimestamp',
    'extract', 'epoch', 'year', 'month', 'day', 'hour', 'minute',
    'second', 'trim', 'lower', 'upper', 'length', 'substring',
    'replace', 'concat', 'count', 'sum', 'avg', 'min', 'max',
    'array', 'json', 'jsonb', 'operator', 'begin', 'commit',
    'rollback', 'transaction', 'schema', 'role', 'user', 'session',
    'local', 'temp', 'temporary', 'view', 'materialized', 'if',
    'only', 'returning', 'values', 'do', 'nothing', 'conflict',
    'excluded', 'lateral', 'rows', 'range', 'preceding', 'following',
    'unbounded', 'partition', 'over', 'window', 'filter', 'within',
    'ordinality', 'recursive', 'cte', 'fetch', 'first', 'last',
    'next', 'prior', 'absolute', 'relative', 'forward', 'backward',
    'no', 'action', 'cascade', 'restrict', 'isolation', 'level',
    'read', 'committed', 'repeatable', 'serializable', 'write',
    'deferrable', 'initially', 'deferred', 'immediate', 'enable',
    'disable', 'row', 'security', 'force', 'owner',
}


# ---------------------------------------------------------------------------
# Metrics Computation
# ---------------------------------------------------------------------------

def compute_pcs(predictions: List[Dict]) -> Dict[str, Any]:
    """Compute Policy Creation Success rate.

    Checks syntactic validity of generated CREATE POLICY statements.

    Args:
        predictions: List of prediction dicts with 'predicted_sql'.

    Returns:
        Dict with 'pcs' score and per-sample details.
    """
    successes = 0
    details = []

    for pred in predictions:
        pred_sql = pred.get("predicted_sql", "")
        policies = extract_create_policies(pred_sql)

        if not policies:
            details.append({
                "id": pred["id"],
                "success": False,
                "reason": "no CREATE POLICY found",
            })
            continue

        all_valid = True
        reasons = []
        for policy_sql in policies:
            comp = parse_policy_components(policy_sql)
            if comp is None:
                all_valid = False
                reasons.append("parse failed")
                continue

            # Check required components
            if not comp["target_table"]:
                all_valid = False
                reasons.append("missing target table (ON clause)")
            if not comp["operation"]:
                all_valid = False
                reasons.append("missing operation (FOR clause)")
            if not comp["has_using"] and not comp["has_with_check"]:
                all_valid = False
                reasons.append("missing both USING and WITH CHECK")

            # Check balanced parentheses
            depth = 0
            for c in policy_sql:
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
            if depth != 0:
                all_valid = False
                reasons.append(f"unbalanced parentheses (depth={depth})")

        if all_valid:
            successes += 1

        details.append({
            "id": pred["id"],
            "success": all_valid,
            "reason": "; ".join(reasons) if reasons else "ok",
            "policy_count": len(policies),
        })

    pcs = successes / len(predictions) if predictions else 0
    return {"pcs": pcs, "successes": successes, "total": len(predictions), "details": details}


def compute_component_accuracy(predictions: List[Dict]) -> Dict[str, Any]:
    """Compute RLS Component Accuracy.

    Components: target_table, operation, to_role, has_using,
    has_with_check, mode, policy_count.

    Args:
        predictions: List of prediction dicts.

    Returns:
        Dict with overall and per-component accuracy.
    """
    component_names = [
        "target_table", "operation", "has_using",
        "has_with_check", "mode", "policy_count",
    ]

    correct_counts = defaultdict(int)
    total_counts = defaultdict(int)
    per_sample = []

    for pred in predictions:
        gold_policies = extract_create_policies(pred["gold_sql"])
        pred_policies = extract_create_policies(pred.get("predicted_sql", ""))

        gold_comps = [parse_policy_components(p) for p in gold_policies]
        pred_comps = [parse_policy_components(p) for p in pred_policies]

        gold_comps = [c for c in gold_comps if c is not None]
        pred_comps = [c for c in pred_comps if c is not None]

        sample_correct = {}

        # Policy count
        count_match = len(gold_comps) == len(pred_comps)
        correct_counts["policy_count"] += int(count_match)
        total_counts["policy_count"] += 1
        sample_correct["policy_count"] = count_match

        # Compare first policy (if exists) for component matching
        if gold_comps and pred_comps:
            gc = gold_comps[0]
            pc = pred_comps[0]

            for comp_name in ["target_table", "operation", "has_using",
                              "has_with_check", "mode"]:
                match = gc[comp_name] == pc[comp_name]
                correct_counts[comp_name] += int(match)
                total_counts[comp_name] += 1
                sample_correct[comp_name] = match
        else:
            for comp_name in ["target_table", "operation", "has_using",
                              "has_with_check", "mode"]:
                total_counts[comp_name] += 1
                sample_correct[comp_name] = False

        per_sample.append({"id": pred["id"], "components": sample_correct})

    # Compute per-component accuracy
    per_component = {}
    for comp_name in component_names:
        total = total_counts[comp_name]
        correct = correct_counts[comp_name]
        per_component[comp_name] = correct / total if total > 0 else 0

    # Overall
    total_all = sum(total_counts.values())
    correct_all = sum(correct_counts.values())
    overall = correct_all / total_all if total_all > 0 else 0

    return {
        "overall_accuracy": overall,
        "per_component": per_component,
        "details": per_sample,
    }


def compute_predicate_f1(predictions: List[Dict]) -> Dict[str, Any]:
    """Compute Predicate Atom F1.

    Extracts predicate atoms from USING and WITH CHECK clauses,
    then computes set-based precision, recall, F1.

    Args:
        predictions: List of prediction dicts.

    Returns:
        Dict with macro-averaged Predicate F1 and per-sample details.
    """
    f1_scores = []
    details = []

    for pred in predictions:
        gold_policies = extract_create_policies(pred["gold_sql"])
        pred_policies = extract_create_policies(
            pred.get("predicted_sql", "")
        )

        # Collect all predicate atoms across all policies
        gold_atoms = set()
        pred_atoms = set()

        for policy_sql in gold_policies:
            comp = parse_policy_components(policy_sql)
            if comp:
                gold_atoms |= extract_predicate_atoms(comp["using_clause"])
                gold_atoms |= extract_predicate_atoms(
                    comp["with_check_clause"]
                )

        for policy_sql in pred_policies:
            comp = parse_policy_components(policy_sql)
            if comp:
                pred_atoms |= extract_predicate_atoms(comp["using_clause"])
                pred_atoms |= extract_predicate_atoms(
                    comp["with_check_clause"]
                )

        # Compute F1
        if not gold_atoms and not pred_atoms:
            f1 = 1.0
        elif not gold_atoms or not pred_atoms:
            f1 = 0.0
        else:
            intersection = gold_atoms & pred_atoms
            precision = len(intersection) / len(pred_atoms)
            recall = len(intersection) / len(gold_atoms)
            f1 = (
                2 * precision * recall / (precision + recall)
                if (precision + recall) > 0
                else 0.0
            )

        f1_scores.append(f1)
        details.append({
            "id": pred["id"],
            "f1": f1,
            "gold_count": len(gold_atoms),
            "pred_count": len(pred_atoms),
        })

    avg_f1 = sum(f1_scores) / len(f1_scores) if f1_scores else 0
    return {"predicate_atom_f1": avg_f1, "details": details}


def compute_attribute_f1(predictions: List[Dict]) -> Dict[str, Any]:
    """Compute Attribute Grounding F1.

    Compares session attributes (current_setting('app.xxx', true))
    extracted from gold vs predicted SQL.

    Args:
        predictions: List of prediction dicts.

    Returns:
        Dict with overall and per-type attribute F1.
    """
    f1_scores = []
    s_f1_scores = []
    details = []

    for pred in predictions:
        gold_attrs = extract_attributes_from_sql(pred["gold_sql"])
        pred_attrs = extract_attributes_from_sql(
            pred.get("predicted_sql", "")
        )

        # Focus on subject attributes (most meaningful for ABAC)
        gold_s = gold_attrs["s_attributes"]
        pred_s = pred_attrs["s_attributes"]

        if not gold_s and not pred_s:
            s_f1 = 1.0
        elif not gold_s or not pred_s:
            s_f1 = 0.0
        else:
            inter = gold_s & pred_s
            prec = len(inter) / len(pred_s)
            rec = len(inter) / len(gold_s)
            s_f1 = (
                2 * prec * rec / (prec + rec)
                if (prec + rec) > 0
                else 0.0
            )

        s_f1_scores.append(s_f1)

        # All attributes combined
        gold_all = (
            gold_attrs["s_attributes"]
            | gold_attrs["e_attributes"]
        )
        pred_all = (
            pred_attrs["s_attributes"]
            | pred_attrs["e_attributes"]
        )

        if not gold_all and not pred_all:
            f1 = 1.0
        elif not gold_all or not pred_all:
            f1 = 0.0
        else:
            inter = gold_all & pred_all
            prec = len(inter) / len(pred_all)
            rec = len(inter) / len(gold_all)
            f1 = (
                2 * prec * rec / (prec + rec)
                if (prec + rec) > 0
                else 0.0
            )

        f1_scores.append(f1)
        details.append({
            "id": pred["id"],
            "attr_f1": f1,
            "subject_attr_f1": s_f1,
            "gold_s": sorted(gold_s),
            "pred_s": sorted(pred_s),
        })

    avg_f1 = sum(f1_scores) / len(f1_scores) if f1_scores else 0
    avg_s_f1 = sum(s_f1_scores) / len(s_f1_scores) if s_f1_scores else 0

    return {
        "attribute_grounding_f1": avg_f1,
        "subject_attr_f1": avg_s_f1,
        "details": details,
    }


def evaluate(args: argparse.Namespace) -> None:
    """Run all evaluations.

    Args:
        args: Parsed command-line arguments.
    """
    logger.info(f"Loading predictions from {args.predictions_path}")
    with open(args.predictions_path) as f:
        predictions = json.load(f)
    logger.info(f"Loaded {len(predictions)} predictions")

    # Compute all metrics
    logger.info("Computing PCS...")
    pcs_result = compute_pcs(predictions)

    logger.info("Computing Component Accuracy...")
    comp_result = compute_component_accuracy(predictions)

    logger.info("Computing Predicate Atom F1...")
    pred_f1_result = compute_predicate_f1(predictions)

    logger.info("Computing Attribute Grounding F1...")
    attr_f1_result = compute_attribute_f1(predictions)

    # Summary
    summary = {
        "model": args.predictions_path,
        "num_samples": len(predictions),
        "metrics": {
            "PCS": pcs_result["pcs"],
            "Component_Accuracy": comp_result["overall_accuracy"],
            "Component_Accuracy_Detail": comp_result["per_component"],
            "Predicate_Atom_F1": pred_f1_result["predicate_atom_f1"],
            "Attribute_Grounding_F1": attr_f1_result["attribute_grounding_f1"],
            "Subject_Attr_F1": attr_f1_result["subject_attr_f1"],
        },
    }

    # Print summary
    print("\n" + "=" * 60)
    print(f"EVALUATION RESULTS: {args.predictions_path}")
    print("=" * 60)
    print(f"  Samples: {len(predictions)}")
    print(f"  PCS (Policy Creation Success): {pcs_result['pcs']:.4f}")
    print(f"  Component Accuracy (overall):  {comp_result['overall_accuracy']:.4f}")
    for comp_name, acc in comp_result["per_component"].items():
        print(f"    - {comp_name}: {acc:.4f}")
    print(f"  Predicate Atom F1:             {pred_f1_result['predicate_atom_f1']:.4f}")
    print(f"  Attribute Grounding F1:        {attr_f1_result['attribute_grounding_f1']:.4f}")
    print(f"    - Subject Attr F1:           {attr_f1_result['subject_attr_f1']:.4f}")
    print("=" * 60)

    # Save detailed results
    full_results = {
        "summary": summary,
        "pcs": pcs_result,
        "component_accuracy": comp_result,
        "predicate_atom_f1": pred_f1_result,
        "attribute_grounding_f1": attr_f1_result,
    }

    output_path = args.output_path
    with open(output_path, "w") as f:
        json.dump(full_results, f, indent=2, ensure_ascii=False)
    logger.info(f"Detailed results saved to {output_path}")


def main():
    parser = argparse.ArgumentParser(description="text2RLS evaluation")
    parser.add_argument(
        "--predictions_path", type=str, required=True,
        help="Path to predictions JSON",
    )
    parser.add_argument(
        "--output_path", type=str, required=True,
        help="Path to save detailed results JSON",
    )
    args = parser.parse_args()
    evaluate(args)


if __name__ == "__main__":
    main()
