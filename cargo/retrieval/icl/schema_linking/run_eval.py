"""End-to-end: build prompts for a split, run the LLM retriever, evaluate.

Run this on the GPU server (conda env `vllm`) after parse_schema.py and
build_gold.py have produced outputs/tables.json, gold_tables.json, catalog.txt.
"""
from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

from build_prompt import build_prompt, select_demos
from evaluate import evaluate
from retriever import HFRetriever

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def main() -> None:
    here = Path(__file__).parent
    out_dir = here / "outputs"
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=str(Path.home() / "models" / "Llama-3.1-8B"))
    ap.add_argument("--split", default="dev", choices=["dev", "test", "train"])
    ap.add_argument("--k", type=int, default=8, help="number of few-shot demos")
    ap.add_argument("--batch-size", type=int, default=8)
    args = ap.parse_args()

    tables = json.loads((out_dir / "tables.json").read_text())["tables"]
    known = {t["table"] for t in tables}
    catalog = (out_dir / "catalog.txt").read_text()
    gold = json.loads((out_dir / "gold_tables.json").read_text())

    demos = select_demos(gold, k=args.k)
    logger.info("Selected %d demos (targets: %s)",
                len(demos), [d.tables for d in demos])

    eval_ids = [pid for pid, g in gold.items() if g["split"] == args.split]
    eval_ids.sort(key=int)
    questions = [gold[pid]["question"] for pid in eval_ids]
    prompts = [build_prompt(catalog, demos, q) for q in questions]
    logger.info("Evaluating split=%s on %d items", args.split, len(eval_ids))
    logger.info("Prompt[0] approx tokens: ~%d", len(prompts[0]) // 4)

    retriever = HFRetriever(args.model, known, batch_size=args.batch_size)
    preds_list = retriever.predict(prompts)
    predictions = {pid: preds for pid, preds in zip(eval_ids, preds_list)}

    gold_for_split = {pid: gold[pid]["gold_tables"] for pid in eval_ids}
    report = evaluate(predictions, gold_for_split)

    (out_dir / f"predictions_{args.split}.json").write_text(
        json.dumps(predictions, indent=2))
    (out_dir / f"eval_report_{args.split}.json").write_text(
        json.dumps(report, indent=2))

    agg = report["aggregate"]
    logger.info("=== %s (n=%d) ===", args.split, report["n"])
    for key in ("precision", "recall", "f1", "exact_match", "full_coverage"):
        logger.info("  %-14s %.4f", key, agg[key])


if __name__ == "__main__":
    main()
