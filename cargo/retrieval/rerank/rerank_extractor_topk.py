"""Schema-Constrained Reranker for cascade top-K predictions.

Implements Top-K candidate selection (paper §IV-C, Eqs. 16-17):
  Step 1 — Schema-validity filter: discard candidates whose target table is
           absent from the schema, or whose row anchors do not resolve to a
           column of the schema; keep all candidates if none survives.
  Step 2 — Convex score: combine the cascade likelihood ell_joint (softmax-
           normalised over surviving candidates), an NL-grounding score
           g_gr (PMI keyword map η), and a parsimony prior g_ps on the
           row-anchor size, weighted by (alpha_cf, alpha_gr, alpha_ps).

The keyword map η is built by build_keyword_map.py from the training
corpus via PMI and loaded from a JSON file (--keyword-map).

Usage:
  python3 cargo/retrieval/rerank/rerank_extractor_topk.py \
    --cascade-jsonl predictions/cascade_top3.jsonl \
    --test-jsonl    data/test_text2rls.jsonl \
    --keyword-map   cargo/extractor/data/keyword_map_eta.json \
    --out           predictions/cascade_reranked.jsonl
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# ---------------------------------------------------------------------------
# Schema parsing  (DDL string -> {table: [cols]})
# ---------------------------------------------------------------------------

_CT_RE = re.compile(
    r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([\w.\"]+)\s*\((.+?)\)\s*;",
    re.I | re.S,
)


def parse_schema(schema_str: str) -> Dict[str, List[str]]:
    """Parse schema string in either DDL or compact format.

    Compact format: lines like '# table_name: col1, col2, col3'
    DDL format: CREATE TABLE statements.

    Returns {table_name: [col1, col2, ...]} plus unqualified aliases.
    """
    out: Dict[str, List[str]] = {}

    # Try compact format first (# table: col1, col2, ...)
    compact_lines = [
        l.strip() for l in schema_str.split("\n")
        if l.strip().startswith("#")
    ]
    if compact_lines:
        for line in compact_lines:
            line = line.lstrip("# ").strip()
            if ":" not in line:
                continue
            table, cols_str = line.split(":", 1)
            table = table.strip()
            cols = [c.strip() for c in cols_str.split(",") if c.strip()]
            if table and cols:
                out[table] = cols
                if "." in table:
                    out[table.split(".")[-1]] = cols
        if out:
            return out

    # Fallback to DDL parsing
    for m in _CT_RE.finditer(schema_str):
        table = m.group(1).replace('"', '').strip()
        body = m.group(2)
        cols: List[str] = []
        for line in body.split(','):
            line = line.strip().split('\n')[0].strip()
            if not line:
                continue
            toks = line.split()
            if not toks:
                continue
            first = toks[0].replace('"', '').strip().upper()
            if first in {"PRIMARY", "FOREIGN", "CHECK", "UNIQUE",
                         "CONSTRAINT", "INDEX", "LIKE"}:
                continue
            col_name = toks[0].replace('"', '').strip()
            if col_name:
                cols.append(col_name)
        if not cols:
            continue
        out[table] = cols
        if '.' in table:
            out[table.split('.')[-1]] = cols
    return out


# ---------------------------------------------------------------------------
# Step 1: schema-validity filter
# ---------------------------------------------------------------------------

def _resolves(col_ref: str, pred_table: str, schema: Dict[str, List[str]]) -> bool:
    """A row anchor resolves if its column exists in its own table (when the
    anchor is table-qualified) or in the predicted target table otherwise."""
    parts = col_ref.replace('"', '').strip().split('.')
    col = parts[-1]
    table = '.'.join(parts[:-1]) if len(parts) > 1 else pred_table
    cols = schema.get(table) or schema.get(table.split('.')[-1]) or []
    return col in cols


def is_schema_valid(
    candidate: Dict,
    schema: Dict[str, List[str]],
) -> bool:
    """Validate(C_K, Sigma): the predicted table exists in Sigma and every
    predicted row anchor resolves to a column of Sigma."""
    pred_table = (candidate.get("pred_table") or "").replace('"', '').strip()
    if not pred_table:
        return False
    if pred_table not in schema and pred_table.split('.')[-1] not in schema:
        return False
    return all(_resolves(c, pred_table, schema) for c in candidate.get("pred_o", []) if c.strip())


# ---------------------------------------------------------------------------
# PMI keyword map η  (loaded from JSON, built by build_keyword_map.py)
# ---------------------------------------------------------------------------

# Global keyword map: anchor_name -> [keyword1, keyword2, ...]
# Loaded once via load_keyword_map() before reranking starts.
_ETA: Dict[str, List[str]] = {}


def load_keyword_map(path: str) -> None:
    """Load the PMI keyword map η from JSON into the module global."""
    global _ETA
    with open(path) as fh:
        _ETA = json.load(fh)
    print(f"=== loaded keyword map η: |η|={len(_ETA)} entries ===",
          file=sys.stderr)


# ---------------------------------------------------------------------------
# Per-anchor grounding score  (paper Eq: |η(a) ∩ tokens(N)| / |η(a)|)
# ---------------------------------------------------------------------------

_Q_TOK_RE = re.compile(r"[a-z][a-z']+")


def _tokenize_question_set(text: str) -> set:
    """Lowercase token set from the NL requirement."""
    return set(_Q_TOK_RE.findall(text.lower()))


def _token_match(keyword: str, q_tokens: set) -> bool:
    """Check if keyword matches any token in q_tokens.

    Exact match first, then prefix/containment for morphological
    robustness (e.g., 'employee' matches 'employees').
    Only tries containment for keywords with len >= 4 to avoid
    false positives from short keywords like 'or', 'an'.
    """
    if keyword in q_tokens:
        return True
    if len(keyword) >= 4:
        return any(keyword in qt or qt in keyword for qt in q_tokens)
    return False


def _anchor_grounding(anchor_name: str, q_tokens: set) -> float:
    """Fraction of the anchor's keywords eta(a) that occur in N; None if a has no keywords."""
    col_name = anchor_name.split(".")[-1].strip().lower()
    keywords = _ETA.get(col_name)
    if not keywords:
        return None
    hits = sum(1 for k in keywords if _token_match(k, q_tokens))
    return hits / len(keywords)


def candidate_grounding(candidate: Dict, question: str) -> float:
    """g_gr: average over the predicted anchors (S + O + E) of the eta-keyword fraction.

    Anchors without an eta entry carry no keywords and are left out of the
    average; 0.5 when no anchor of the candidate has keywords (or it has none).
    """
    all_anchors: List[str] = []
    all_anchors.extend(candidate.get("pred_s", []))
    all_anchors.extend(candidate.get("pred_o", []))
    all_anchors.extend(candidate.get("pred_e", []))

    q_tokens = _tokenize_question_set(question)
    scores = [g for g in (_anchor_grounding(a, q_tokens) for a in all_anchors)
              if g is not None]
    if not scores:
        return 0.5
    return sum(scores) / len(scores)


# ---------------------------------------------------------------------------
# Parsimony score
# ---------------------------------------------------------------------------

def candidate_parsimony(candidate: Dict) -> float:
    n_o = len(candidate.get("pred_o", []))
    return max(0.0, 1.0 - 0.1 * n_o)


# ---------------------------------------------------------------------------
# Cascade likelihood -> [0, 1] via softmax over surviving candidates
# ---------------------------------------------------------------------------

def softmax_likelihoods(candidates: List[Dict]) -> List[float]:
    """Convert ell_joint (negative log-prob per token) to a [0,1] ranking signal.

    Softmax over the surviving candidates places the cascade likelihood on
    the same scale as the grounding/parsimony scores, so the convex
    combination is meaningful.
    """
    ells = [c.get("ell_joint", -1e9) for c in candidates]
    if not ells:
        return []
    if len(ells) == 1:
        return [1.0]
    m = max(ells)
    exps = [math.exp(e - m) for e in ells]
    z = sum(exps)
    return [e / z for e in exps]


# ---------------------------------------------------------------------------
# Two-step reranker
# ---------------------------------------------------------------------------

def cascade_rerank(
    candidates: List[Dict],
    question: str,
    schema: Dict[str, List[str]],
    alpha_cf: float = 0.4,
    alpha_gr: float = 0.4,
    alpha_ps: float = 0.2,
) -> Tuple[Dict, List[Dict]]:
    """Returns (best_candidate, all_scored_candidates_with_diagnostics).

    Convex score s(c) = alpha_cf*g_cf + alpha_gr*g_gr + alpha_ps*g_ps (Eq. 16).
    """
    # Step 1: schema-validity filter
    valid = [c for c in candidates if is_schema_valid(c, schema)]
    used_fallback = False
    if not valid:
        valid = list(candidates)            # fallback: never return empty
        used_fallback = True

    # Step 2: convex score
    ell_norm = softmax_likelihoods(valid)
    scored: List[Dict] = []
    for c, g_cf in zip(valid, ell_norm):
        g_gr = candidate_grounding(c, question)
        g_ps = candidate_parsimony(c)
        s = alpha_cf * g_cf + alpha_gr * g_gr + alpha_ps * g_ps
        out_c = dict(c)
        out_c["rerank_score"] = round(s, 4)
        out_c["g_cf"] = round(g_cf, 4)
        out_c["g_gr"] = round(g_gr, 4)
        out_c["g_ps"] = round(g_ps, 4)
        out_c["fallback"] = used_fallback
        scored.append(out_c)

    scored.sort(key=lambda x: -x["rerank_score"])
    return scored[0], scored


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _soea_match(c: Dict, gold: Dict) -> bool:
    return (
        (c.get("pred_table") or "").lower() == (gold.get("gold_table") or "").lower()
        and (c.get("pred_cmd") or "") == (gold.get("gold_cmd") or "")
        and set(c.get("pred_s", [])) == set(gold.get("gold_s", []))
        and set(c.get("pred_o", [])) == set(gold.get("gold_o", []))
        and set(c.get("pred_e", [])) == set(gold.get("gold_e", []))
    )


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--cascade-jsonl", required=True,
                   help="Output JSONL from infer_codes3b_cascade_topk.py")
    p.add_argument("--test-jsonl", required=True,
                   help="Test set JSONL with 'schema' field per item")
    p.add_argument("--out", required=True)
    p.add_argument("--keyword-map", default=None,
                   help="Path to keyword_map_eta.json (PMI map)")
    p.add_argument("--alpha-cf", type=float, default=0.4)
    p.add_argument("--alpha-gr", type=float, default=0.4)
    p.add_argument("--alpha-ps", type=float, default=0.2)
    args = p.parse_args()

    # Load PMI keyword map if provided
    if args.keyword_map:
        load_keyword_map(args.keyword_map)
    else:
        print("WARNING: no --keyword-map provided, grounding uses "
              "sub-token fallback only", file=sys.stderr)

    # Load schemas + questions keyed by item id
    schemas: Dict[str, Dict[str, List[str]]] = {}
    questions: Dict[str, str] = {}
    with open(args.test_jsonl) as fh:
        for line in fh:
            item = json.loads(line)
            iid = item.get("id") or item.get("orig_id")
            schemas[iid] = parse_schema(item.get("schema", ""))
            questions[iid] = item.get("question", "")
    print(f"=== loaded {len(schemas)} schemas ===", file=sys.stderr)

    n = 0
    n_top1_match = 0
    n_oracle_match = 0
    n_rerank_changed_choice = 0
    n_fallback = 0

    out_p = Path(args.out)
    out_p.parent.mkdir(parents=True, exist_ok=True)

    with open(args.cascade_jsonl) as fin, out_p.open("w") as fout:
        for line in fin:
            row = json.loads(line)
            iid = row.get("id")
            schema = schemas.get(iid, {})
            question = questions.get(iid, "")
            cands = row.get("candidates", [])
            if not cands:
                continue

            best, scored = cascade_rerank(
                cands, question, schema,
                alpha_cf=args.alpha_cf,
                alpha_gr=args.alpha_gr,
                alpha_ps=args.alpha_ps,
            )

            # Metrics
            n += 1
            if _soea_match(best, row):
                n_top1_match += 1
            if any(_soea_match(c, row) for c in cands):
                n_oracle_match += 1
            if best.get("rank") and best.get("rank") != 1:
                n_rerank_changed_choice += 1
            if best.get("fallback"):
                n_fallback += 1

            out_row = dict(row)
            out_row["reranked"] = best
            out_row["scored_candidates"] = scored
            fout.write(json.dumps(out_row) + "\n")

    print(f"\n=== rerank summary (n={n}) ===", file=sys.stderr)
    print(f"  top-1 SOEA after rerank: {n_top1_match}/{n} = {100*n_top1_match/n:.1f}%",
          file=sys.stderr)
    print(f"  oracle@K (top-K bound):  {n_oracle_match}/{n} = {100*n_oracle_match/n:.1f}%",
          file=sys.stderr)
    print(f"  rerank changed choice:   {n_rerank_changed_choice}/{n} "
          f"= {100*n_rerank_changed_choice/n:.1f}%",
          file=sys.stderr)
    print(f"  schema-filter fallback:  {n_fallback}/{n} = {100*n_fallback/n:.1f}%",
          file=sys.stderr)


if __name__ == "__main__":
    main()
