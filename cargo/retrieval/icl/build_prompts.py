"""Build StructICL prompts for all 481 eval items.

Usage:
    python3 cargo/retrieval/icl/build_prompts.py \
        --policies data/RLSbench/single_policy/policies.json \
        --test-cases data/RLSbench/single_policy/test_cases.json \
        --schema data/RLSbench/schema/trimmed_schema.sql \
        --extractor-predictions <extractor_predictions>.jsonl \
        --job-roles data/RLSbench/schema/runtime_context/job_role_vocab.json \
        --output prompts_structicl.json \
        --k 5 --lam-diversity 0.3 --min-reliability 0.4
"""
from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

from sklearn.feature_extraction.text import TfidfVectorizer

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from cargo.retrieval.icl.struct_icl import select_demos_mmr

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


SYSTEM_TEMPLATE = """You are generating PostgreSQL Row-Level Security policies.

Generate exactly one PostgreSQL CREATE POLICY statement.
Output SQL only. Do not explain.

Rules:

Use only the provided schema context. Do not invent tables, columns, functions, or session variables. Literal values come from the natural-language policy, not the schema.
Read session variables with current_setting('app.<variable>', true) (e.g. current_setting('app.employee_id', true)).
Use only these session variables when needed:
app.employee_id, app.user_id, app.customer_id, app.job_role, app.department_id, app.team_id, app.region_id, app.user_clearance_level, app.position_level, app.tenant_id.
Use app.employee_id for internal employee identity, including employees, managers, engineers, HR, finance, auditors, assignees, approvers, authors, owners, and hierarchy relations.
Use app.user_id for application account identity, including auth.users, access grants, temporal access records, API access, login accounts, and security events triggered by application accounts.
Use app.customer_id for customer portal identity.
Add fail-closed IS NOT NULL guards for required session variables.
For SELECT and DELETE, use USING.
For INSERT, use WITH CHECK.
For UPDATE, use USING for old-row eligibility and WITH CHECK for new-row validity.
For ALL, use both USING and WITH CHECK.
Put old-row preconditions in USING, new-row postconditions in WITH CHECK, and security invariants in both.
Use EXISTS or NOT EXISTS when the policy requires related supporting rows or absence of blocking rows.
Use WITH RECURSIVE for direct/indirect hierarchy requirements unless an allowed helper function is explicitly provided.
Preserve the exact column names shown in the schema context and the literal values stated in the policy.

Runtime session variables:
Allowed session variables (read with current_setting('app.<name>', true)):
  app.employee_id, app.user_id, app.customer_id, app.job_role, app.department_id, app.team_id, app.region_id, app.user_clearance_level, app.position_level, app.tenant_id
allowed app.job_role values:
  {job_roles}
"""


def _fmt_attrs(soea: dict) -> str:
    s = ", ".join(soea.get("pred_s", [])) or "(none)"
    o = ", ".join(soea.get("pred_o", [])) or "(none)"
    e = ", ".join(soea.get("pred_e", [])) or "(none)"
    return (
        f"\nPREDICTED ATTRIBUTES (use as guidance):\n"
        f"  target_table: {soea.get('pred_table', '?')}\n"
        f"  operation:    {soea.get('pred_cmd', '?')}\n"
        f"  S attributes: {s}\n"
        f"  O attributes: {o}\n"
        f"  E attributes: {e}\n"
    )


def build_prompt(
    test_item: dict,
    test_soea: dict,
    demo_ids: list,
    demo_pool_by_id: dict,
    demo_soeas: dict,
    system: str,
    schema_body: str,
) -> str:
    parts = [system, "\nSchema:\n", schema_body, "\n"]
    for did in demo_ids:
        d = demo_pool_by_id[did]
        d_soea = demo_soeas.get(did, {})
        parts.append(f"\nExample:\n{_fmt_attrs(d_soea).rstrip()}")
        parts.append(f"\nNatural-language policy:\n{d['question']}\n\nSQL:\n{d['sql']}\n")
    parts.append(_fmt_attrs(test_soea))
    parts.append(f"\nNatural-language policy:\n{test_item['question']}\n\nSQL:\n")
    return "".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--policies", required=True)
    ap.add_argument("--test-cases", required=True)
    ap.add_argument("--schema", required=True)
    ap.add_argument("--extractor-predictions", required=True)
    ap.add_argument("--job-roles", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--k", type=int, default=5)
    ap.add_argument("--lam-diversity", type=float, default=0.3)
    ap.add_argument("--min-reliability", type=float, default=0.4)
    args = ap.parse_args()

    policies = json.loads(Path(args.policies).read_text())
    eval_items = json.loads(Path(args.test_cases).read_text())
    jr_vocab = json.loads(Path(args.job_roles).read_text())
    schema_body = "\n".join(
        line for line in Path(args.schema).read_text().split("\n")
        if not line.lstrip().startswith("--")
    ).strip()

    pol_by_id = {p["id"]: p for p in policies}
    eval_ids = {t["id"] for t in eval_items}

    # Load extractor predictions
    extractor_by = {}
    with open(args.extractor_predictions) as f:
        for line in f:
            r = json.loads(line)
            extractor_by[r["id"]] = r
    logger.info("Loaded %d extractor predictions", len(extractor_by))

    # Build TF-IDF matrix over all 490 policies
    all_ids = [p["id"] for p in policies]
    texts = [p["question"] for p in policies]
    vec = TfidfVectorizer(stop_words="english", ngram_range=(1, 2), min_df=1)
    X = vec.fit_transform(texts)
    id_to_row = {pid: i for i, pid in enumerate(all_ids)}

    system = SYSTEM_TEMPLATE.format(job_roles=", ".join(sorted(jr_vocab)))

    # For each eval item, select demos via StructICL MMR
    prompts = []
    for tc in eval_items:
        pid = tc["id"]
        test_item = pol_by_id[pid]
        test_soea = extractor_by.get(pid, {})

        demo_ids = select_demos_mmr(
            test_item=test_item,
            test_soea=test_soea,
            demo_pool=policies,
            demo_soeas=extractor_by,
            tfidf_matrix=X,
            tfidf_id_to_row=id_to_row,
            k=args.k,
            lam_diversity=args.lam_diversity,
            min_reliability=args.min_reliability,
        )

        prompt = build_prompt(
            test_item, test_soea, demo_ids,
            pol_by_id, extractor_by, system, schema_body,
        )
        prompts.append({"id": pid, "prompt": prompt, "demo_ids": demo_ids})

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    json.dump(prompts, open(args.output, "w"), ensure_ascii=False)
    lens = [len(p["prompt"]) for p in prompts]
    logger.info("Output: %s  n=%d  avg_len=%d  max_len=%d",
                args.output, len(prompts), sum(lens)//len(lens), max(lens))


if __name__ == "__main__":
    main()
