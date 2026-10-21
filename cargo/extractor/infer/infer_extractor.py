"""Two-pass cascade inference for CodeS-3B + LoRA cascade extractor.

Pass 1 (scope):  schema + question  →  predicted TARGET_TABLE + TARGET_CMD
Pass 2 (anchor): schema + pred_scope + question  →  predicted S + O + E

Each test item requires TWO forward passes through the same LoRA adapter.

Output JSONL fields:
  {id, scope_raw, anchor_raw,
   pred_table, pred_cmd, pred_s, pred_o, pred_e,
   gold_table, gold_cmd, gold_s, gold_o, gold_e,
   scope_ms, anchor_ms, gen_ms, difficulty, attribute_pattern}

Usage:
  CUDA_VISIBLE_DEVICES=0 python3 cargo/extractor/infer/infer_extractor.py \
    --adapter adapters/codes3b_cascade_extractor/final \
    --test data/test_text2rls.jsonl \
    --out predictions/extractor_cascaded_top1.jsonl
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Dict, List

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

# ---------------------------------------------------------------------------
# Prompt templates (must match train_codes3b_cascade.py)
# ---------------------------------------------------------------------------

SCOPE_PROMPT_TPL = "{schema}\n\nREQUEST: {question}\n\nSCOPE:\n"
ANCHOR_PROMPT_TPL = (
    "{schema}\n\n"
    "TARGET_TABLE: {table}\nTARGET_CMD: {cmd}\n\n"
    "REQUEST: {question}\n\n"
    "ANCHOR:\n"
)

# ---------------------------------------------------------------------------
# Tag parsers
# ---------------------------------------------------------------------------

_SCOPE_RE = {
    "table": re.compile(r"TARGET_TABLE:[ \t]*([^\n]+)", re.I),
    "cmd":   re.compile(r"TARGET_CMD:[ \t]*([^\n]+)", re.I),
}
_ANCHOR_RE = {
    "s": re.compile(r"^S:[ \t]*([^\n]*)", re.I | re.M),
    "o": re.compile(r"^O:[ \t]*([^\n]*)", re.I | re.M),
    "e": re.compile(r"^E:[ \t]*([^\n]*)", re.I | re.M),
}


def parse_scope(text: str) -> Dict[str, str]:
    out: Dict[str, str] = {"table": "", "cmd": ""}
    for k, regex in _SCOPE_RE.items():
        m = regex.search(text)
        if m:
            out[k] = m.group(1).strip()
    return out


def parse_anchor(text: str) -> Dict[str, List[str]]:
    out: Dict[str, List[str]] = {"s": [], "o": [], "e": []}
    for k, regex in _ANCHOR_RE.items():
        m = regex.search(text)
        if not m:
            continue
        val = m.group(1).strip()
        out[k] = [x.strip() for x in val.split(",") if x.strip()] if val else []
    return out


def gold_from_item(r: Dict) -> Dict[str, object]:
    return {
        "table": r.get("gold_table") or r.get("target_table"),
        "cmd": (r.get("action") or r.get("target_cmd") or "SELECT").upper(),
        "s": sorted(set(
            a.lower() for a in (r.get("gold_subject_accessors")
                                or r.get("s_attributes") or [])
        )),
        "o": sorted(set(r.get("gold_columns") or r.get("o_attributes") or [])),
        "e": sorted(set(
            e.lower() for e in (r.get("gold_environment_accessors")
                                or r.get("e_attributes") or [])
        )),
    }


# ---------------------------------------------------------------------------
# Single-item generate helper
# ---------------------------------------------------------------------------

def generate_one(
    model: torch.nn.Module,
    tok: AutoTokenizer,
    prompt: str,
    max_new: int,
    max_len: int,
    device: str,
) -> tuple[str, float]:
    """Generate greedy output. Returns (decoded_text, elapsed_ms)."""
    enc = tok(
        prompt, return_tensors="pt",
        truncation=True, max_length=max_len,
    ).to(device)
    prompt_len = enc.input_ids.shape[1]

    t0 = time.perf_counter()
    with torch.no_grad():
        gen = model.generate(
            **enc, max_new_tokens=max_new,
            do_sample=False, pad_token_id=tok.pad_token_id,
        )
    elapsed_ms = (time.perf_counter() - t0) * 1000
    raw = tok.decode(gen[0][prompt_len:], skip_special_tokens=True)
    return raw, elapsed_ms


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--test", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--base", default="seeklhy/codes-3b")
    p.add_argument("--adapter", required=True)
    p.add_argument("--max-new", type=int, default=200)
    p.add_argument("--max-len", type=int, default=4096)
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--device", default="cuda")
    args = p.parse_args()

    print(f"=== loading base {args.base} ===", file=sys.stderr)
    tok = AutoTokenizer.from_pretrained(args.base, trust_remote_code=True)
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token
    base = AutoModelForCausalLM.from_pretrained(
        args.base, trust_remote_code=True,
        torch_dtype=torch.bfloat16,
        device_map={"": args.device},
    )
    print(f"=== loading LoRA adapter {args.adapter} ===", file=sys.stderr)
    model = PeftModel.from_pretrained(base, args.adapter)
    model.eval()

    with open(args.test) as fh:
        items = [json.loads(line) for line in fh]
    if args.limit:
        items = items[: args.limit]
    print(f"=== cascade inference over {len(items)} items ===",
          file=sys.stderr)

    out_p = Path(args.out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    t_start = time.perf_counter()

    # Running metrics
    n = 0
    n_tbl_ok = n_cmd_ok = 0
    soea_ok = 0
    o_item_ok = 0

    with out_p.open("w") as f:
        for i, item in enumerate(items):
            # --- Pass 1: scope ---
            scope_prompt = SCOPE_PROMPT_TPL.format(
                schema=item["schema"], question=item["question"],
            )
            scope_raw, scope_ms = generate_one(
                model, tok, scope_prompt,
                args.max_new, args.max_len, args.device,
            )
            scope = parse_scope(scope_raw)
            pred_table = scope["table"] or None
            pred_cmd = scope["cmd"].upper() if scope["cmd"] else None

            # --- Pass 2: anchor (using Stage-1 prediction) ---
            anchor_prompt = ANCHOR_PROMPT_TPL.format(
                schema=item["schema"], question=item["question"],
                table=pred_table or "UNKNOWN",
                cmd=pred_cmd or "SELECT",
            )
            anchor_raw, anchor_ms = generate_one(
                model, tok, anchor_prompt,
                args.max_new, args.max_len, args.device,
            )
            anchor = parse_anchor(anchor_raw)

            gold = gold_from_item(item)
            gen_ms = scope_ms + anchor_ms

            row = {
                "id": item.get("id") or item.get("orig_id"),
                "scope_raw": scope_raw[:400],
                "anchor_raw": anchor_raw[:400],
                "pred_table": pred_table,
                "pred_cmd": pred_cmd,
                "pred_s": [s.lower() for s in anchor["s"]],
                "pred_o": anchor["o"],
                "pred_e": [e.lower() for e in anchor["e"]],
                "gold_table": gold["table"],
                "gold_cmd": gold["cmd"],
                "gold_s": gold["s"],
                "gold_o": gold["o"],
                "gold_e": gold["e"],
                "scope_ms": round(scope_ms, 1),
                "anchor_ms": round(anchor_ms, 1),
                "gen_ms": round(gen_ms, 1),
                "difficulty": item.get("difficulty"),
                "attribute_pattern": item.get("attribute_pattern"),
            }
            f.write(json.dumps(row) + "\n")

            # Running metrics
            n += 1
            tbl_ok = (
                (row["pred_table"] or "").lower()
                == (gold["table"] or "").lower()
            )
            cmd_ok = (row["pred_cmd"] or "") == (gold["cmd"] or "")
            s_ok = set(row["pred_s"]) == set(gold["s"])
            o_ok = set(row["pred_o"]) == set(gold["o"])
            e_ok = set(row["pred_e"]) == set(gold["e"])
            if tbl_ok:
                n_tbl_ok += 1
            if cmd_ok:
                n_cmd_ok += 1
            if o_ok:
                o_item_ok += 1
            if s_ok and o_ok and e_ok and cmd_ok:
                soea_ok += 1

            if (i + 1) % 20 == 0 or i == len(items) - 1:
                tot = time.perf_counter() - t_start
                eta = tot / (i + 1) * (len(items) - i - 1)
                print(
                    f"  [{i+1:3d}/{len(items)}] "
                    f"tbl={n_tbl_ok/n:.3f} cmd={n_cmd_ok/n:.3f} "
                    f"O-item={o_item_ok/n:.3f} SOEA={soea_ok/n:.3f} "
                    f"el={tot:.0f}s eta={eta:.0f}s",
                    file=sys.stderr,
                )

    elapsed_min = (time.perf_counter() - t_start) / 60
    print(f"\n=== DONE in {elapsed_min:.1f} min ===", file=sys.stderr)
    print(f"=== FINAL (n={n}) ===", file=sys.stderr)
    print(f"  Table:     {n_tbl_ok}/{n} = {100*n_tbl_ok/n:.1f}%",
          file=sys.stderr)
    print(f"  CMD:       {n_cmd_ok}/{n} = {100*n_cmd_ok/n:.1f}%",
          file=sys.stderr)
    print(f"  O-item:    {o_item_ok}/{n} = {100*o_item_ok/n:.1f}%",
          file=sys.stderr)
    print(f"  SOEA-item: {soea_ok}/{n} = {100*soea_ok/n:.1f}%",
          file=sys.stderr)


if __name__ == "__main__":
    main()
