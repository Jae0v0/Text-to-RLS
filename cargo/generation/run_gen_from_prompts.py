"""Generate predictions from pre-built prompt files.

Reads a prompts JSON file [{id, prompt}], calls LLM API for each,
extracts CREATE POLICY SQL, outputs [{id, predicted_sql}] for eval.

Usage:
    python3 cargo/generation/run_gen_from_prompts.py \
        --prompts prompts_cargo.json \
        --model deepseek-v3.2 \
        --endpoint https://api.xty.app/v1 \
        --api_key sk-xxx \
        --out predictions/cargo_predictions.json \
        --workers 6
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import openai

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

CREATE_POLICY_RE = re.compile(
    r"(CREATE\s+POLICY\s+.*?;)", re.IGNORECASE | re.DOTALL
)


def extract_sql(raw: str) -> str:
    """Extract CREATE POLICY statements from LLM output."""
    matches = CREATE_POLICY_RE.findall(raw or "")
    if matches:
        return "\n".join(m.strip() for m in matches)
    # Fallback: return raw if it looks like SQL
    if raw and "CREATE POLICY" in raw.upper():
        return raw.strip()
    return ""


def generate_one(
    client: openai.OpenAI,
    item: dict,
    model: str,
    max_tokens: int,
    no_think: bool,
) -> dict:
    """Generate prediction for one item."""
    messages = [{"role": "user", "content": item["prompt"]}]
    kwargs = {
        "model": model,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.0,
    }
    if no_think:
        kwargs["extra_body"] = {"chat_template_kwargs": {"enable_thinking": False}}

    try:
        resp = client.chat.completions.create(**kwargs)
        raw = resp.choices[0].message.content or ""
        sql = extract_sql(raw)
        return {"id": item["id"], "predicted_sql": sql, "raw_len": len(raw)}
    except Exception as e:
        logger.error("Item %d failed: %s", item["id"], e)
        return {"id": item["id"], "predicted_sql": "", "error": str(e)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompts", required=True, help="Path to prompts JSON")
    ap.add_argument("--model", required=True)
    ap.add_argument("--endpoint", default="https://api.xty.app/v1")
    ap.add_argument("--api_key", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--max_tokens", type=int, default=4096)
    ap.add_argument("--no_think", action="store_true")
    ap.add_argument("--resume", action="store_true", help="Resume from existing output")
    args = ap.parse_args()

    prompts = json.loads(Path(args.prompts).read_text())
    logger.info("Loaded %d prompts from %s", len(prompts), args.prompts)

    # Resume support
    done_ids = set()
    results = []
    out_path = Path(args.out)
    if args.resume and out_path.exists():
        results = json.loads(out_path.read_text())
        done_ids = {r["id"] for r in results}
        logger.info("Resuming: %d items already done", len(done_ids))

    todo = [p for p in prompts if p["id"] not in done_ids]
    logger.info("%d items to generate (model=%s, workers=%d)", len(todo), args.model, args.workers)

    client = openai.OpenAI(base_url=args.endpoint, api_key=args.api_key)

    t0 = time.time()
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(generate_one, client, item, args.model, args.max_tokens, args.no_think): item
            for item in todo
        }
        for i, fut in enumerate(as_completed(futures), 1):
            result = fut.result()
            results.append(result)
            if i % 50 == 0 or i == len(todo):
                elapsed = time.time() - t0
                logger.info(
                    "generated %d/%d (%.1f items/min)",
                    i, len(todo), i / (elapsed / 60),
                )
                # Checkpoint
                out_path.parent.mkdir(parents=True, exist_ok=True)
                sorted_results = sorted(results, key=lambda x: x["id"])
                json.dump(sorted_results, open(out_path, "w"), ensure_ascii=False, indent=2)

    # Final write
    sorted_results = sorted(results, key=lambda x: x["id"])
    # Clean output: only id + predicted_sql
    clean = [{"id": r["id"], "predicted_sql": r["predicted_sql"]} for r in sorted_results]
    json.dump(clean, open(out_path, "w"), ensure_ascii=False, indent=2)
    logger.info("Done! %d predictions written to %s", len(clean), args.out)


if __name__ == "__main__":
    main()
