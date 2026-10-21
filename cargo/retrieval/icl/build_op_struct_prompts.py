"""Build CARGO generation prompts (paper §IV-D, Algorithm 2 lines 1-14).

For every evaluated item the selected scope/anchors (S*, A*) come from the
reranked extractor output; demonstrations are retrieved from the pool K by
op_struct_icl.select_demos. The prompt concatenates, in order:
  (i)   CREATE POLICY rules: fail-closed IS NOT NULL, USING / WITH CHECK channels;
  (ii)  the relevant part of the schema (tables of T* and of the row anchors);
  (iii) the k selected demonstrations;
  (iv)  the predicted scope and anchors (the operation fixes the channels);
  (v)   the requirement N and the runtime context Omega.

Pool K = validated Practical-Structure entries (--kb) + RLSbench items,
with leave-one-out on the requirement text.

Usage:
    python3 cargo/retrieval/icl/build_op_struct_prompts.py \
        --policies data/RLSbench/single_policy/policies.json \
        --test-cases data/RLSbench/single_policy/test_cases.json \
        --kb cargo/retrieval/icl/kb_practical_structure.json \
        --schema data/RLSbench/schema/trimmed_schema.sql \
        --runtime-context data/RLSbench/schema/runtime_context/runtime_context_spec.json \
        --job-roles data/RLSbench/schema/runtime_context/job_role_vocab.json \
        --extractor predictions/cascade_reranked.jsonl \
        --output prompts_cargo.json
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Dict, List

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from cargo.retrieval.icl.op_struct_icl import (
    ALPHA_A, ALPHA_S, K_DEMOS, XI, Demo, anchor_set, as_list, policy_scope, select_demos,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


RULES = """You are generating PostgreSQL Row-Level Security policies.

Generate exactly one PostgreSQL CREATE POLICY statement.
Output SQL only. Do not explain.

Rules:

Use only the provided schema context. Do not invent tables, columns, functions, or session variables. Literal values come from the natural-language policy, not the schema.
Read session variables with current_setting('app.<variable>', true) (e.g. current_setting('app.employee_id', true)).
Use only the session variables listed in the runtime context.
Use app.employee_id for internal employee identity, including employees, managers, engineers, HR, finance, auditors, assignees, approvers, authors, owners, and hierarchy relations.
Use app.user_id for application account identity, including auth.users, access grants, temporal access records, API access, login accounts, and security events triggered by application accounts.
Use app.customer_id for customer portal identity.
Add fail-closed IS NOT NULL guards for required session variables.
USING decides which existing rows are visible (SELECT, UPDATE, DELETE); WITH CHECK decides which new or updated rows are admissible (INSERT, UPDATE).
{op_instruction}
Put old-row preconditions in USING, new-row postconditions in WITH CHECK, and security invariants in both.
Use EXISTS or NOT EXISTS when the policy requires related supporting rows or absence of blocking rows.
Use WITH RECURSIVE for direct/indirect hierarchy requirements unless an allowed helper function is explicitly provided.
Preserve the exact column names shown in the schema context and the literal values stated in the policy."""

OP_INSTRUCTIONS = {
    "SELECT": "This is a SELECT policy. Use USING clause only.",
    "DELETE": "This is a DELETE policy. Use USING clause only.",
    "INSERT": "This is an INSERT policy. Use WITH CHECK clause only.",
    "UPDATE": "This is an UPDATE policy. Use USING for old-row eligibility and WITH CHECK for new-row validity.",
    "ALL": "This is an ALL-operations policy. Use both USING and WITH CHECK.",
}

_TABLE_DDL_RE = re.compile(r"CREATE TABLE (?:IF NOT EXISTS )?(\w+\.\w+)\s*\(.*?\n\);", re.S)


def load_ddl(path: str) -> Dict[str, str]:
    """{schema.table: CREATE TABLE statement} from the schema file."""
    text = Path(path).read_text()
    return {m.group(1).lower(): m.group(0) for m in _TABLE_DDL_RE.finditer(text)}


def relevant_schema(ddl: Dict[str, str], table: str, row_anchors: List[str]) -> str:
    """DDL of the target table and of the tables the row anchors refer to."""
    wanted = [table.lower()]
    for a in row_anchors:
        parts = a.lower().split(".")
        if len(parts) >= 3:
            wanted.append(".".join(parts[:-1]))
    tables = [t for t in dict.fromkeys(wanted) if t in ddl]
    if not tables:                     # unknown table: fall back to the full schema
        tables = list(ddl)
    return "\n\n".join(ddl[t] for t in tables)


def fmt_scope_anchors(table: str, op: str, run: List[str], row: List[str], env: List[str]) -> str:
    def lst(xs: List[str]) -> str:
        return ", ".join(xs) if xs else "(none)"
    return (f"Scope: table={table}, operation={op}\n"
            f"Anchors: runtime={lst(run)}; row={lst(row)}; environment={lst(env)}")


def fmt_runtime_context(spec: Dict, job_roles: List[str]) -> str:
    lines = [f"  {v['name']} ({v['type']}): {v['purpose']}" for v in spec["variables"]]
    return ("Runtime context (read with current_setting('app.<name>', true)):\n"
            + "\n".join(lines)
            + "\nAllowed app.job_role values:\n  " + ", ".join(sorted(job_roles)))


def build_pool(kb: List[Dict], policies: List[Dict], include_benchmark: bool) -> List[Demo]:
    pool: List[Demo] = []
    sources = [("kb", kb)] + ([("rls", policies)] if include_benchmark else [])
    for prefix, rows in sources:
        for r in rows:
            table, op = policy_scope(r["sql"])
            pool.append(Demo(
                id=f"{prefix}:{r['id']}", question=r["question"], sql=r["sql"],
                table=table, op=op,
                run=tuple(as_list(r.get("s_attributes"))),
                row=tuple(as_list(r.get("o_attributes"))),
                env=tuple(as_list(r.get("e_attributes"))),
            ))
    return pool


def load_selected(path: str) -> Dict[int, Dict]:
    """(S*, A*) per item: the reranked candidate if present, else the top-1 candidate."""
    out: Dict[int, Dict] = {}
    with open(path) as fh:
        for line in fh:
            r = json.loads(line)
            best = r.get("reranked") or (r.get("candidates") or [r])[0]
            out[int(r["id"])] = best
    return out


def build_prompt(item: Dict, sel: Dict, demos: List[Demo], ddl: Dict[str, str],
                 runtime_ctx: str, full_schema: bool) -> str:
    table = sel.get("pred_table") or ""
    op = (sel.get("pred_cmd") or "SELECT").upper()
    run, row, env = sel.get("pred_s", []), sel.get("pred_o", []), sel.get("pred_e", [])
    schema = "\n\n".join(ddl.values()) if full_schema else relevant_schema(ddl, table, row)

    parts = [RULES.format(op_instruction=OP_INSTRUCTIONS.get(op, OP_INSTRUCTIONS["SELECT"])),
             f"Schema:\n{schema}"]
    for i, d in enumerate(demos, 1):
        parts.append(f"Example {i}:\n"
                     + fmt_scope_anchors(d.table, d.op, list(d.run), list(d.row), list(d.env))
                     + f"\nRequirement: {d.question}\nSQL:\n{d.sql}")
    parts.append("Predicted scope and anchors (use as guidance):\n"
                 + fmt_scope_anchors(table, op, run, row, env))
    parts.append(f"Requirement:\n{item['question']}\n\n{runtime_ctx}")
    parts.append("SQL:\n")
    return "\n\n".join(parts)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--policies", required=True)
    ap.add_argument("--test-cases", required=True, help="items with test cases are evaluated")
    ap.add_argument("--kb", required=True, help="validated Practical-Structure pool (JSON list)")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--runtime-context", required=True)
    ap.add_argument("--job-roles", required=True)
    ap.add_argument("--extractor", required=True,
                    help="reranked extractor output (rerank_extractor_topk.py)")
    ap.add_argument("--output", required=True)
    ap.add_argument("--k", type=int, default=K_DEMOS)
    ap.add_argument("--xi", type=float, default=XI)
    ap.add_argument("--alpha-s", type=float, default=ALPHA_S)
    ap.add_argument("--alpha-a", type=float, default=ALPHA_A)
    ap.add_argument("--full-schema", action="store_true",
                    help="put the whole schema in (ii) instead of the relevant tables")
    ap.add_argument("--no-benchmark-pool", action="store_true",
                    help="pool K = Practical-Structure entries only")
    args = ap.parse_args()

    policies = json.loads(Path(args.policies).read_text())
    eval_ids = {it["id"] for it in json.loads(Path(args.test_cases).read_text())}
    kb = json.loads(Path(args.kb).read_text())
    ddl = load_ddl(args.schema)
    runtime_ctx = fmt_runtime_context(json.loads(Path(args.runtime_context).read_text()),
                                      json.loads(Path(args.job_roles).read_text()))
    selected = load_selected(args.extractor)
    pool = build_pool(kb, policies, include_benchmark=not args.no_benchmark_pool)
    logger.info("pool |K| = %d (%s)", len(pool), dict(Counter(d.op for d in pool)))

    prompts = []
    n_missing = 0
    for item in policies:
        if item["id"] not in eval_ids:
            continue
        sel = selected.get(item["id"])
        if sel is None:
            n_missing += 1
            sel = {}
        a_star = anchor_set(sel.get("pred_s", []), sel.get("pred_o", []), sel.get("pred_e", []))
        demos = select_demos(
            item["question"], sel.get("pred_table") or "", sel.get("pred_cmd") or "SELECT",
            a_star, pool, k=args.k, xi=args.xi, alpha_s=args.alpha_s, alpha_a=args.alpha_a,
        )
        prompts.append({
            "id": item["id"],
            "prompt": build_prompt(item, sel, demos, ddl, runtime_ctx, args.full_schema),
            "demo_ids": [d.id for d in demos],
            "cmd": (sel.get("pred_cmd") or "SELECT").upper(),
        })

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    json.dump(prompts, open(args.output, "w"), ensure_ascii=False, indent=1)
    lens = [len(p["prompt"]) for p in prompts]
    logger.info("wrote %d prompts to %s (avg %d chars, max %d); %d items without extractor output",
                len(prompts), args.output, sum(lens) // max(1, len(lens)), max(lens, default=0),
                n_missing)


if __name__ == "__main__":
    main()
