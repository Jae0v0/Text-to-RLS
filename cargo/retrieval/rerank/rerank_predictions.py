"""Apply post-hoc reranking to prediction files.

Reranking has two components:
1. audit_and_repair: Inject IS NOT NULL guards for missing current_setting refs
2. case_insensitive_literal_rewrite: LOWER() wrap on column = 'literal' comparisons

Usage:
    python3 cargo/retrieval/rerank/rerank_predictions.py --input pred_in/DS3.2_structicl.json --output pred_in/DS3.2_reranked.json
    python3 cargo/retrieval/rerank/rerank_predictions.py --input pred_in/DS3.2_structicl.json --output pred_in/DS3.2_audit_only.json --mode audit
    python3 cargo/retrieval/rerank/rerank_predictions.py --input pred_in/DS3.2_structicl.json --output pred_in/DS3.2_literal_only.json --mode literal
"""
from __future__ import annotations

import argparse
import json
import logging
import re
from pathlib import Path
from typing import List, Tuple

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# audit_and_repair: Inject IS NOT NULL guards
# ---------------------------------------------------------------------------

_APP_REF = re.compile(
    r"current_setting\(\s*'app\.([A-Za-z_][A-Za-z_0-9]*)'",
    re.IGNORECASE,
)

_GUARD = re.compile(
    r"current_setting\(\s*'app\.([A-Za-z_][A-Za-z_0-9]*)'\s*,\s*true\s*\)\s+IS\s+NOT\s+NULL",
    re.IGNORECASE,
)

_CHANNEL_HEAD = re.compile(
    r"((?:USING|WITH\s+CHECK)\s*\()(\s*)",
    re.IGNORECASE,
)


def audit_and_repair(sql_statements: List[str]) -> Tuple[List[str], dict]:
    """Inject IS NOT NULL guards for missing current_setting refs."""
    joined = "\n".join(sql_statements)
    referenced = sorted(set(m.group(1) for m in _APP_REF.finditer(joined)))
    guarded = sorted(set(m.group(1) for m in _GUARD.finditer(joined)))
    missing = sorted(set(referenced) - set(guarded))

    if not missing:
        return sql_statements, {
            "referenced": referenced,
            "lgtm": guarded,
            "injected": [],
        }

    injection = " AND ".join(
        f"current_setting('app.{x}', true) IS NOT NULL" for x in missing
    )

    new_stmts: List[str] = []
    for stmt in sql_statements:
        def _inject(match: "re.Match[str]") -> str:
            head, ws = match.group(1), match.group(2)
            return f"{head}{ws}{injection} AND "
        new_stmts.append(_CHANNEL_HEAD.sub(_inject, stmt))

    return new_stmts, {
        "referenced": referenced,
        "lgtm": guarded,
        "injected": missing,
    }


# ---------------------------------------------------------------------------
# case_insensitive_literal_rewrite
# ---------------------------------------------------------------------------

_EQ_LITERAL = re.compile(
    r"([A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)*)\s*(=|!=|<>)\s*'((?:[^'\\]|\\.)*)'",
    re.IGNORECASE,
)
_IN_LITERAL = re.compile(
    r"([A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)*)\s+IN\s*\(\s*((?:'(?:[^'\\]|\\.)*'\s*,?\s*)+)\)",
    re.IGNORECASE,
)


def _rewrite_eq(m: "re.Match[str]") -> str:
    col, op, lit = m.group(1), m.group(2), m.group(3)
    if "." not in col:
        return m.group(0)
    return f"LOWER({col}::text) {op} LOWER('{lit}')"


def _rewrite_in(m: "re.Match[str]") -> str:
    col, lits_block = m.group(1), m.group(2)
    if "." not in col:
        return m.group(0)
    parts = [p.strip() for p in re.findall(r"'(?:[^'\\]|\\.)*'", lits_block)]
    if not parts:
        return m.group(0)
    rewritten = ", ".join(f"LOWER({p})" for p in parts)
    return f"LOWER({col}::text) IN ({rewritten})"


def case_insensitive_literal_rewrite(sql_statements: List[str]) -> List[str]:
    """Rewrite literal comparisons to be case-insensitive."""
    out: List[str] = []
    for stmt in sql_statements or []:
        rewritten = _EQ_LITERAL.sub(_rewrite_eq, stmt)
        rewritten = _IN_LITERAL.sub(_rewrite_in, rewritten)
        out.append(rewritten)
    return out


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def rerank(sql: str, mode: str = "both") -> str:
    """Apply reranking to a single predicted_sql string."""
    if not sql.strip():
        return sql
    stmts = [sql]
    if mode in ("both", "audit"):
        stmts, _ = audit_and_repair(stmts)
    if mode in ("both", "literal"):
        stmts = case_insensitive_literal_rewrite(stmts)
    return "\n".join(stmts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="Input predictions JSON [{id, predicted_sql}]")
    ap.add_argument("--output", required=True, help="Output reranked predictions JSON")
    ap.add_argument("--mode", default="both", choices=["both", "audit", "literal"],
                    help="Which reranking to apply: both (default), audit only, literal only")
    args = ap.parse_args()

    preds = json.loads(Path(args.input).read_text())
    logger.info("Loaded %d predictions from %s", len(preds), args.input)

    n_changed = 0
    for p in preds:
        original = p.get("predicted_sql", "")
        reranked = rerank(original, args.mode)
        if reranked != original:
            n_changed += 1
        p["predicted_sql"] = reranked

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    json.dump(preds, open(args.output, "w"), ensure_ascii=False, indent=2)
    logger.info("Done! %d/%d items changed. Output: %s", n_changed, len(preds), args.output)


if __name__ == "__main__":
    main()
