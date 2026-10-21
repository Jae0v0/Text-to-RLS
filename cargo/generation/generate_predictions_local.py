"""Generate ICL predictions for LOCAL fine-tuned text-to-SQL models.

Supports:
  - CodeT5+-770M  (Salesforce/codet5p-770m, encoder-decoder T5)
  - CodeS-1B      (seeklhy/codes-1b, causal LM, gpt_bigcode)
  - CodeS-3B      (seeklhy/codes-3b, causal LM, gpt_bigcode)

Shot/strategy combinations evaluated in the paper:
  - 0-shot (no examples, strategy ignored)  - 5-shot * {random, structicl}

Reuses ICLSelector + prompt templates from generate_predictions.py
to keep selection logic identical to the API-based experiments.

Output JSON is compatible with run_test_cases.py --mode pred.

Usage (on a GPU machine, from the repository root):

  # 0-shot, CodeS-3B
  python3 cargo/generation/generate_predictions_local.py \
    --model_path seeklhy/codes-3b --model_type codes \
    --fullschema data/RLSbench/schema/trimmed_schema.sql \
    --shot 0 --out preds/codes3b_0shot.json

  # 5-shot structicl, CodeS-1B
  python3 cargo/generation/generate_predictions_local.py \
    --model_path seeklhy/codes-1b --model_type codes \
    --fullschema data/RLSbench/schema/trimmed_schema.sql \
    --shot 5 --strategy structicl --out preds/codes1b_5shot_structicl.json"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import time
from pathlib import Path
from typing import Dict, List

# Reuse the existing selector and template helpers
sys.path.insert(0, str(Path(__file__).parent))
from generate_predictions import (  # noqa: E402
    SYSTEM_PROMPT,
    ICL_BLOCK,
    EXAMPLE_TEMPLATE,
    EXAMPLE_TEMPLATE_NOSCHEMA,
    QUERY_TEMPLATE,
    QUERY_TEMPLATE_NOSCHEMA,
    ICLSelector,
    derive_job_roles,
    extract_policy,
)

import torch  # noqa: E402

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Flat prompt builder (chat -> single string, since local models are not
# instruction-tuned for chat).
# ---------------------------------------------------------------------------

def build_flat_prompt(
    target_item: dict,
    examples: List[dict],
    ctx_by_id: Dict[int, str],
    job_roles: str,
    fullschema: str = "",
) -> str:
    """Compose a single flat prompt string ending with 'Answer:\\n'."""
    system_msg = SYSTEM_PROMPT.format(job_roles=job_roles)
    if fullschema:
        system_msg += f"\n\nSchema context:\n{fullschema}"

    if examples:
        if fullschema:
            ex_blocks = [
                EXAMPLE_TEMPLATE_NOSCHEMA.format(
                    i=i, question=ex["question"], sql=ex["sql"],
                )
                for i, ex in enumerate(examples, 1)
            ]
            query_block = QUERY_TEMPLATE_NOSCHEMA.format(
                question=target_item["question"],
            )
        else:
            ex_blocks = [
                EXAMPLE_TEMPLATE.format(
                    i=i,
                    schema_context=ctx_by_id.get(ex["id"], ""),
                    question=ex["question"],
                    sql=ex["sql"],
                )
                for i, ex in enumerate(examples, 1)
            ]
            query_block = QUERY_TEMPLATE.format(
                schema_context=ctx_by_id.get(target_item["id"], ""),
                question=target_item["question"],
            )
        icl_block = ICL_BLOCK.format(
            k=len(examples), examples="\n\n".join(ex_blocks)
        )
        user_msg = f"{icl_block}\n\n{query_block}"
    else:
        # 0-shot: no examples, just the query
        if fullschema:
            user_msg = QUERY_TEMPLATE_NOSCHEMA.format(
                question=target_item["question"],
            )
        else:
            user_msg = QUERY_TEMPLATE.format(
                schema_context=ctx_by_id.get(target_item["id"], ""),
                question=target_item["question"],
            )

    # Flat completion-style prompt for non-chat-tuned models
    return f"{system_msg}\n\n{user_msg}\n\nAnswer:\n"


# ---------------------------------------------------------------------------
# Local model wrappers
# ---------------------------------------------------------------------------

class LocalModel:
    """Thin wrapper around CodeT5+ (seq2seq) and CodeS (causal LM)."""

    def __init__(
        self,
        model_path: str,
        model_type: str,
        device: str = "cuda",
        dtype: str = "bfloat16",
    ) -> None:
        from transformers import (
            AutoTokenizer,
            AutoModelForCausalLM,
            T5ForConditionalGeneration,
        )

        self.model_type = model_type
        self.device = device
        torch_dtype = getattr(torch, dtype) if hasattr(torch, dtype) else torch.float32

        logger.info("loading tokenizer from %s", model_path)
        self.tok = AutoTokenizer.from_pretrained(model_path, trust_remote_code=True)
        if self.tok.pad_token is None:
            self.tok.pad_token = self.tok.eos_token

        logger.info("loading %s model (%s, %s)", model_type, model_path, dtype)
        if model_type == "codet5p":
            self.model = T5ForConditionalGeneration.from_pretrained(
                model_path,
                trust_remote_code=True,
                torch_dtype=torch_dtype,
            ).to(device)
        elif model_type == "codes":
            self.model = AutoModelForCausalLM.from_pretrained(
                model_path,
                trust_remote_code=True,
                torch_dtype=torch_dtype,
                device_map={"": device},
            )
        else:
            raise ValueError(f"unknown model_type: {model_type}")
        self.model.eval()

    @torch.no_grad()
    def generate(
        self,
        prompt: str,
        max_new_tokens: int = 512,
        max_input_len: int = 4096,
        num_beams: int = 1,
    ) -> str:
        enc = self.tok(
            prompt,
            return_tensors="pt",
            truncation=True,
            max_length=max_input_len,
        ).to(self.device)
        out = self.model.generate(
            **enc,
            max_new_tokens=max_new_tokens,
            num_beams=num_beams,
            do_sample=False,
            pad_token_id=self.tok.pad_token_id,
        )

        if self.model_type == "codet5p":
            # Seq2seq: decoder output starts from token 0
            text = self.tok.decode(out[0], skip_special_tokens=True)
        else:
            # Causal: strip the input prefix
            prompt_len = enc.input_ids.shape[1]
            text = self.tok.decode(out[0][prompt_len:], skip_special_tokens=True)
        return text


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    here = Path(__file__).parent
    repo = here.parents[1]
    ap = argparse.ArgumentParser(
        description="Generate ICL predictions via LOCAL text-to-SQL models",
    )
    ap.add_argument("--model_path", required=True,
                    help="HF model id or local path (e.g. seeklhy/codes-3b)")
    ap.add_argument("--model_type", required=True,
                    choices=["codet5p", "codes"],
                    help="codet5p (seq2seq) or codes (causal LM)")
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
    ap.add_argument("--out", required=True, help="Output predictions JSON")
    ap.add_argument("--shot", type=int, default=5, choices=[0, 1, 5],
                    help="0-shot or 5-shot")
    ap.add_argument(
        "--strategy",
        default="structicl",
        choices=["random", "structicl", "semantic", "operation"],
        help="ICL selection strategy (ignored when --shot 0)",
    )
    ap.add_argument("--max_new_tokens", type=int, default=512)
    ap.add_argument("--max_input_len", type=int, default=4096)
    ap.add_argument("--num_beams", type=int, default=1,
                    help="1 = greedy; >1 = beam search")
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--dtype", default="bfloat16",
                    choices=["bfloat16", "float16", "float32"])
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument(
        "--eval_ids",
        default=str(repo / "data/RLSbench/single_policy/test_cases.json"),
        help="Path to eval JSON whose IDs define the target set "
             "(default: RLSbench single-policy test cases → 490 items)",
    )
    ap.add_argument(
        "--kb",
        default=str(repo / "cargo/retrieval/icl/kb_practical_structure.json"),
        help="Practical-Structure entries added to the demonstration pool K "
        "(pass '' to draw demonstrations from RLSbench items only)",
    )
    ap.add_argument(
        "--fullschema",
        default="",
        help="Path to full schema SQL file (puts schema in system prompt once)",
    )
    args = ap.parse_args()
    if not args.schema_ctx and not args.fullschema:
        ap.error("pass --fullschema (e.g. data/RLSbench/schema/trimmed_schema.sql) "
                 "or --schema_ctx")

    # Load gold + schema context
    gold = json.loads(Path(args.gold).read_text())
    ctx_by_id: Dict[int, str] = {}
    if args.schema_ctx:
        ctx_list = json.loads(Path(args.schema_ctx).read_text())
        ctx_by_id = {c["id"]: c["schema_context"] for c in ctx_list}

    fullschema_text = ""
    if args.fullschema:
        fullschema_text = Path(args.fullschema).read_text()
        logger.info(
            "fullschema mode: %d chars from %s",
            len(fullschema_text), args.fullschema,
        )

    # Filter to eval IDs
    eval_ids_path = args.eval_ids
    if not eval_ids_path:
        candidates = [
            Path(args.gold).parent / "gold_test_cases.json",
            Path(args.gold).parent / "test_case" / "gold_test_cases.json",
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
            "filtered to %d eval IDs (from %s)",
            len(target_items), eval_ids_path,
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
    logger.info("derived %d job_role values", len(job_roles.split(", ")))

    # ICL selector (only used when shot > 0)
    selector = None
    if args.shot > 0:
        selector = ICLSelector(
            pool=pool,
            ctx_by_id=ctx_by_id,
            strategy=args.strategy,
            seed=args.seed,
            demo_ids={e["id"] for e in ps} if ps else None,
        )
        logger.info(
            "ICL selector ready: strategy=%s, k=%d, pool=%d",
            args.strategy, args.shot, len(gold),
        )
    else:
        logger.info("0-shot mode: no ICL examples")

    # Load local model
    model = LocalModel(
        model_path=args.model_path,
        model_type=args.model_type,
        device=args.device,
        dtype=args.dtype,
    )

    # Generate
    results: List[Dict] = []
    t0 = time.perf_counter()
    for i, item in enumerate(target_items, 1):
        examples = (
            selector.select(item["id"], k=args.shot)
            if selector is not None else []
        )
        prompt = build_flat_prompt(
            item, examples, ctx_by_id, job_roles, fullschema=fullschema_text,
        )
        try:
            raw = model.generate(
                prompt,
                max_new_tokens=args.max_new_tokens,
                max_input_len=args.max_input_len,
                num_beams=args.num_beams,
            )
            sql = extract_policy(raw)
        except Exception as e:  # noqa: BLE001
            logger.warning("item %s failed: %s", item["id"], e)
            sql = ""
        results.append({"id": item["id"], "predicted_sql": sql})

        if i % 20 == 0 or i == len(target_items):
            elapsed = time.perf_counter() - t0
            eta = elapsed / i * (len(target_items) - i)
            empty = sum(1 for r in results if not r["predicted_sql"])
            logger.info(
                "  [%d/%d] empty=%d el=%.0fs eta=%.0fs",
                i, len(target_items), empty, elapsed, eta,
            )

    results.sort(key=lambda r: r["id"])
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text(json.dumps(results, indent=2))

    empty = sum(1 for r in results if not r["predicted_sql"])
    elapsed_min = (time.perf_counter() - t0) / 60
    logger.info(
        "DONE in %.1f min: wrote %d predictions to %s (%d empty)",
        elapsed_min, len(results), args.out, empty,
    )


if __name__ == "__main__":
    main()
