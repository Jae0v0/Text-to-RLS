"""Generate 5-shot ICL predictions for API-based models.

For each benchmark item: select 5 ICL examples using a retrieval strategy,
build a prompt with demonstrations, call the model, extract the CREATE POLICY
statement. Outputs predictions.json compatible with run_test_cases.py --mode pred.

Strategies:
  random    - 5 random examples (leave-one-out)
  semantic  - TF-IDF cosine similarity on question text
  operation - same operation type first, fill from any
  structicl     - same operation type + TF-IDF similarity (recommended)
"""
from __future__ import annotations

import argparse
import json
import logging
import random
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from openai import OpenAI
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Prompt template (same as generate_predictions.py, with ICL block inserted)
# ---------------------------------------------------------------------------
SYSTEM_PROMPT = """You are generating PostgreSQL Row-Level Security policies.
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
current_setting('app.<name>', true) ALWAYS returns text. When comparing it to a non-text column, cast it to the column's type: integer columns use ::integer (e.g. employee_id = current_setting('app.employee_id', true)::integer), numeric columns use ::numeric, boolean columns use ::boolean. Never compare an integer/numeric/boolean column directly to current_setting without a cast.
Always include the FOR <command> clause that matches the operation (FOR SELECT / FOR INSERT / FOR UPDATE / FOR DELETE / FOR ALL).
Preserve the exact column names shown in the schema context and the literal values stated in the policy.
Runtime session variables:
Allowed session variables (read with current_setting('app.<name>', true)):
  app.employee_id, app.user_id, app.customer_id, app.job_role, app.department_id, app.team_id, app.region_id, app.user_clearance_level, app.position_level, app.tenant_id
allowed app.job_role values:
  {job_roles}"""

ICL_BLOCK = """Here are {k} examples of natural-language policies and their correct CREATE POLICY statements:

{examples}

Now generate the policy for the following:"""

EXAMPLE_TEMPLATE = """--- Example {i} ---
Schema context:
{schema_context}
Natural-language policy:
{question}
Answer:
{sql}"""

QUERY_TEMPLATE = """Schema context:
{schema_context}
Natural-language policy:
{question}"""

# Fullschema mode: schema in system prompt once, examples only have Q+A
EXAMPLE_TEMPLATE_NOSCHEMA = """--- Example {i} ---
Natural-language policy:
{question}
Answer:
{sql}"""

QUERY_TEMPLATE_NOSCHEMA = """Natural-language policy:
{question}"""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_OP_RE = re.compile(r"FOR\s+(SELECT|INSERT|UPDATE|DELETE|ALL)\b", re.IGNORECASE)
_ROLE_RE = re.compile(
    r"app\.job_role'\s*,\s*true\s*\)\s*(?:=|IN)\s*(.+?)(?:\)|AND|OR|;|$)", re.IGNORECASE
)
_LITERAL_RE = re.compile(r"'([a-z_][a-z0-9_]*)'")


def extract_operation(sql: str) -> str:
    """Extract FOR <cmd> from a CREATE POLICY statement."""
    m = _OP_RE.search(sql)
    return m.group(1).upper() if m else "UNKNOWN"


def derive_job_roles(gold: List[dict]) -> str:
    """Reconstruct the allowed app.job_role catalog from gold policy literals."""
    roles: set = set()
    for item in gold:
        for m in _ROLE_RE.finditer(item.get("sql", "")):
            roles.update(_LITERAL_RE.findall(m.group(1)))
    return ", ".join(sorted(roles))


def extract_policy(text: str) -> str:
    """Pull the first CREATE POLICY ... ; statement out of a model response."""
    text = text.strip()
    text = re.sub(r"```(?:sql)?", "", text, flags=re.IGNORECASE).strip()
    m = re.search(r"CREATE\s+POLICY\b.*?;", text, flags=re.IGNORECASE | re.DOTALL)
    if m:
        return re.sub(r"\s+", " ", m.group(0)).strip()
    m = re.search(r"CREATE\s+POLICY\b.*", text, flags=re.IGNORECASE | re.DOTALL)
    return (re.sub(r"\s+", " ", m.group(0)).strip() + ";") if m else text


# ---------------------------------------------------------------------------
# ICL Example Selection
# ---------------------------------------------------------------------------
class ICLSelector:
    """Select k ICL examples from a pool using various strategies."""

    def __init__(
        self,
        pool: List[dict],
        ctx_by_id: Dict[int, str],
        strategy: str = "structicl",
        seed: int = 42,
        demo_ids: Optional[set] = None,
    ) -> None:
        """demo_ids: ids that may be selected as demonstrations by the random,
        operation and structicl strategies (the Practical-Structure entries);
        None allows every pool item. The rest of the pool is only indexed."""
        self.pool = pool
        self.demo_ids = demo_ids
        self.ctx_by_id = ctx_by_id
        self.strategy = strategy
        self.rng = random.Random(seed)

        # Precompute operation per item
        self.op_by_id: Dict[int, str] = {}
        for item in pool:
            self.op_by_id[item["id"]] = extract_operation(item["sql"])

        # Precompute TF-IDF similarity matrix for semantic strategies
        if strategy in ("semantic", "structicl"):
            self._build_tfidf()

    def _build_tfidf(self) -> None:
        """Build TF-IDF vectors and precompute similarity."""
        questions = [item["question"] for item in self.pool]
        vectorizer = TfidfVectorizer(
            stop_words="english", max_features=5000, ngram_range=(1, 2)
        )
        self.tfidf_matrix = vectorizer.fit_transform(questions)
        # Pool index by item id
        self.id_to_idx: Dict[int, int] = {
            item["id"]: i for i, item in enumerate(self.pool)
        }

    def select(self, target_id: int, k: int = 5) -> List[dict]:
        """Select k examples for a given target item (leave-one-out)."""
        if self.strategy == "random":
            return self._select_random(target_id, k)
        elif self.strategy == "operation":
            return self._select_operation(target_id, k)
        elif self.strategy == "semantic":
            return self._select_semantic(target_id, k)
        elif self.strategy == "structicl":
            return self._select_structicl(target_id, k)
        else:
            raise ValueError(f"Unknown strategy: {self.strategy}")

    def _eligible(self, item: dict, target_id) -> bool:
        # Practical-Structure ids ("kb:<n>") and RLSbench ids share a numeric range. As in
        # baselines/prompts/demos_icl_random.json, an entry whose number equals the target
        # id is skipped (this affects targets 542-550 only).
        raw = item["id"][3:] if isinstance(item["id"], str) and item["id"].startswith("kb:") else item["id"]
        return str(raw) != str(target_id) and (self.demo_ids is None or item["id"] in self.demo_ids)

    def _select_random(self, target_id: int, k: int) -> List[dict]:
        candidates = [item for item in self.pool if self._eligible(item, target_id)]
        return self.rng.sample(candidates, min(k, len(candidates)))

    def _select_operation(self, target_id: int, k: int) -> List[dict]:
        target_op = self.op_by_id.get(target_id, "UNKNOWN")
        same_op = [
            item for item in self.pool
            if self._eligible(item, target_id) and self.op_by_id.get(item["id"]) == target_op
        ]
        diff_op = [
            item for item in self.pool
            if self._eligible(item, target_id) and self.op_by_id.get(item["id"]) != target_op
        ]
        selected = self.rng.sample(same_op, min(k, len(same_op)))
        if len(selected) < k:
            extra = self.rng.sample(diff_op, min(k - len(selected), len(diff_op)))
            selected.extend(extra)
        return selected[:k]

    def _select_semantic(self, target_id: int, k: int) -> List[dict]:
        target_idx = self.id_to_idx[target_id]
        sims = cosine_similarity(
            self.tfidf_matrix[target_idx : target_idx + 1], self.tfidf_matrix
        ).flatten()
        # Exclude self
        sims[target_idx] = -1.0
        top_indices = np.argsort(sims)[::-1][:k]
        return [self.pool[i] for i in top_indices]

    def _select_structicl(self, target_id: int, k: int) -> List[dict]:
        """Operation-matched + semantic similarity (best strategy)."""
        target_op = self.op_by_id.get(target_id, "UNKNOWN")
        target_idx = self.id_to_idx[target_id]

        sims = cosine_similarity(
            self.tfidf_matrix[target_idx : target_idx + 1], self.tfidf_matrix
        ).flatten()
        sims[target_idx] = -1.0

        # Separate same-op and diff-op indices
        same_op_indices = [
            i for i, item in enumerate(self.pool)
            if self._eligible(item, target_id) and self.op_by_id.get(item["id"]) == target_op
        ]
        diff_op_indices = [
            i for i, item in enumerate(self.pool)
            if self._eligible(item, target_id) and self.op_by_id.get(item["id"]) != target_op
        ]

        # Rank same-op by similarity, take top k
        same_op_ranked = sorted(same_op_indices, key=lambda i: sims[i], reverse=True)
        selected_indices = same_op_ranked[:k]

        # If not enough same-op, fill from diff-op ranked by similarity
        if len(selected_indices) < k:
            diff_op_ranked = sorted(
                diff_op_indices, key=lambda i: sims[i], reverse=True
            )
            remaining = k - len(selected_indices)
            selected_indices.extend(diff_op_ranked[:remaining])

        return [self.pool[i] for i in selected_indices]


# ---------------------------------------------------------------------------
# Prompt Building
# ---------------------------------------------------------------------------
def build_icl_prompt(
    target_item: dict,
    examples: List[dict],
    ctx_by_id: Dict[int, str],
    job_roles: str,
    fullschema: str = "",
) -> List[dict]:
    """Build chat messages with system + ICL examples + target query.

    Args:
        fullschema: If non-empty, use fullschema mode — schema goes in system
            prompt once, examples omit per-item schema context.
    """
    if fullschema:
        # Fullschema mode: schema in system prompt, examples only Q+A
        example_strs = []
        for i, ex in enumerate(examples, 1):
            example_strs.append(
                EXAMPLE_TEMPLATE_NOSCHEMA.format(
                    i=i,
                    question=ex["question"],
                    sql=ex["sql"],
                )
            )
        icl_block = ICL_BLOCK.format(
            k=len(examples), examples="\n\n".join(example_strs)
        )
        query_block = QUERY_TEMPLATE_NOSCHEMA.format(
            question=target_item["question"],
        )
        system_msg = SYSTEM_PROMPT.format(job_roles=job_roles)
        system_msg += f"\n\nSchema context:\n{fullschema}"
    else:
        # Per-item schema mode (original)
        example_strs = []
        for i, ex in enumerate(examples, 1):
            example_strs.append(
                EXAMPLE_TEMPLATE.format(
                    i=i,
                    schema_context=ctx_by_id.get(ex["id"], ""),
                    question=ex["question"],
                    sql=ex["sql"],
                )
            )
        icl_block = ICL_BLOCK.format(
            k=len(examples), examples="\n\n".join(example_strs)
        )
        query_block = QUERY_TEMPLATE.format(
            schema_context=ctx_by_id.get(target_item["id"], ""),
            question=target_item["question"],
        )
        system_msg = SYSTEM_PROMPT.format(job_roles=job_roles)

    user_msg = f"{icl_block}\n\n{query_block}"
    return [
        {"role": "system", "content": system_msg},
        {"role": "user", "content": user_msg},
    ]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    here = Path(__file__).parent
    repo = here.parents[1]
    ap = argparse.ArgumentParser(
        description="Generate 5-shot ICL predictions via OpenAI-compatible API"
    )
    ap.add_argument("--endpoint", default="https://api.xty.app/v1")
    ap.add_argument("--api_key", required=True)
    ap.add_argument("--model", required=True, help="Model name, e.g. gpt-4.1")
    ap.add_argument(
        "--gold",
        default=str(repo / "data/RLSbench/single_policy/policies.json"),
    )
    ap.add_argument(
        "--schema_ctx",
        default="",
        help="Per-item schema context JSON [{id, schema_context}] (not shipped); "
        "either this or --fullschema is required",
    )
    ap.add_argument("--out", required=True, help="Output predictions JSON path")
    ap.add_argument(
        "--strategy",
        default="structicl",
        choices=["random", "semantic", "operation", "structicl"],
        help="ICL example selection strategy (default: structicl)",
    )
    ap.add_argument("--k", type=int, default=5, help="Number of ICL examples")
    ap.add_argument("--temperature", type=float, default=0.0)
    ap.add_argument("--max_tokens", type=int, default=512)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--seed", type=int, default=42, help="Random seed for selection")
    ap.add_argument("--limit", type=int, default=0, help="0 = all items")
    ap.add_argument(
        "--eval_ids",
        default=str(repo / "data/RLSbench/single_policy/test_cases.json"),
        help="Path to eval JSON whose IDs define the target set "
        "(default: RLSbench single-policy test cases → 490 items)",
    )
    ap.add_argument(
        "--kb",
        default=str(repo / "cargo/retrieval/icl/kb_practical_structure.json"),
        help="Demonstration pool K; baselines draw from its enterprise-schema "
        "Practical-Structure entries (pass '' to draw from RLSbench items)",
    )
    ap.add_argument(
        "--fullschema",
        default="",
        help="Path to full schema SQL file. When set, schema goes in system "
        "prompt once and ICL examples omit per-item schema context.",
    )
    args = ap.parse_args()
    if not args.schema_ctx and not args.fullschema:
        ap.error("pass --fullschema (e.g. data/RLSbench/schema/trimmed_schema.sql) "
                 "or --schema_ctx")

    # Load data
    gold = json.loads(Path(args.gold).read_text())
    ctx_by_id: Dict[int, str] = {}
    if args.schema_ctx:
        ctx_list = json.loads(Path(args.schema_ctx).read_text())
        ctx_by_id = {c["id"]: c["schema_context"] for c in ctx_list}

    # Load fullschema if provided
    fullschema_text = ""
    if args.fullschema:
        fullschema_text = Path(args.fullschema).read_text()
        logger.info(
            "Fullschema mode: %d chars from %s", len(fullschema_text), args.fullschema
        )

    # Filter to eval IDs (default: RLSbench single-policy test cases → 490 items)
    eval_ids_path = args.eval_ids
    if not eval_ids_path:
        # Auto-detect gold_test_cases.json relative to benchmark dir
        candidates = [
            Path(args.gold).parent / "gold_test_cases.json",
            Path("/path/to/Text2RLS/benchmark/gold_test_cases.json"),
        ]
        for c in candidates:
            if c.exists():
                eval_ids_path = str(c)
                break

    target_items = gold
    if eval_ids_path and Path(eval_ids_path).exists():
        eval_data = json.loads(Path(eval_ids_path).read_text())
        if isinstance(eval_data, list):
            eval_id_set = {int(e["id"]) for e in eval_data}
        else:
            eval_id_set = {
                int(e["id"])
                for e in eval_data.get("item_results", eval_data)
            }
        target_items = [g for g in gold if g["id"] in eval_id_set]
        logger.info(
            "Filtered to %d eval IDs (from %s)", len(target_items), eval_ids_path
        )
    else:
        logger.warning(
            "No eval_ids file found — generating for all %d gold items",
            len(gold),
        )

    if args.limit:
        target_items = target_items[: args.limit]

    job_roles = derive_job_roles(gold)
    # Baseline demonstrations are drawn from the enterprise-schema Practical-Structure
    # entries of K (entries without a source_url); RLSbench items are only indexed.
    pool = list(gold)
    ps = []
    if args.kb:
        ps = [dict(e, id=f"kb:{e['id']}") for e in json.loads(Path(args.kb).read_text())
              if "source_url" not in e]
        pool += ps
    logger.info("Derived %d job_role values", len(job_roles.split(", ")))

    selector = ICLSelector(
        pool=pool, ctx_by_id=ctx_by_id, strategy=args.strategy, seed=args.seed,
        demo_ids={e["id"] for e in ps} if ps else None,
    )
    logger.info(
        "ICL selector ready: strategy=%s, k=%d, pool=%d",
        args.strategy,
        args.k,
        len(gold),
    )

    # API client
    client = OpenAI(base_url=args.endpoint, api_key=args.api_key)

    # Draw demonstrations sequentially in item order before the parallel API calls, so the
    # seeded selection does not depend on thread scheduling.
    demos_by_id = {item["id"]: selector.select(item["id"], k=args.k) for item in target_items}

    def gen(item: dict) -> Dict:
        examples = demos_by_id[item["id"]]
        messages = build_icl_prompt(
            item, examples, ctx_by_id, job_roles, fullschema=fullschema_text
        )
        try:
            resp = client.chat.completions.create(
                model=args.model,
                messages=messages,
                temperature=args.temperature,
                max_tokens=args.max_tokens,
            )
            sql = extract_policy(resp.choices[0].message.content)
        except Exception as e:  # noqa: BLE001
            logger.warning("item %s failed: %s", item["id"], e)
            sql = ""
        return {"id": item["id"], "predicted_sql": sql}

    # Generate predictions
    results: List[Dict] = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = {ex.submit(gen, it): it["id"] for it in target_items}
        for i, fut in enumerate(as_completed(futures), 1):
            results.append(fut.result())
            if i % 50 == 0:
                logger.info("generated %d/%d", i, len(target_items))

    results.sort(key=lambda r: r["id"])
    Path(args.out).write_text(json.dumps(results, indent=2))
    empty = sum(1 for r in results if not r["predicted_sql"])
    logger.info(
        "wrote %d predictions to %s (%d empty)", len(results), args.out, empty
    )


if __name__ == "__main__":
    main()
