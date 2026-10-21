"""Build the cascade supervision corpus D (paper §IV-B).

D merges three sources, each example cast as (N, Sigma, Omega, S, A):
  1. Authorization-Template instantiations (build_spider_auth.py output; already
     one scope row and one anchor row per example).
  2. Practical-Structure examples.
  3. Failure-Case examples.
PS/FC rows carry the full target (TARGET_TABLE, TARGET_CMD, S, O, E); each is
split into a scope row (gold scope as target) and an anchor row (gold scope in
the prompt, anchors as target), matching train_codes3b_cascade.py.

Any example whose requirement text equals an RLSbench requirement is dropped,
so D is used only for scope/anchor supervision. A fraction of the examples is
held out as the development split used for hyperparameter selection.

Usage:
  python3 cargo/extractor/train/build_cascade_dataset.py \
    --auth-templates data/spider_auth_templates.jsonl \
    --practical-structure data/practical_structure.jsonl \
    --failure-cases data/failure_cases.jsonl \
    --requirements data/RLSbench/requirements.json \
    --out data/cascade_train.jsonl --dev-out data/cascade_dev.jsonl
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from collections import Counter
from pathlib import Path
from typing import Dict, List, Tuple

SCOPE_KEYS = ("TARGET_TABLE", "TARGET_CMD")
ANCHOR_KEYS = ("S", "O", "E")


def _norm(text: str) -> str:
    return " ".join(text.lower().split())


def _parse_target(target: str) -> Dict[str, str]:
    out = {}
    for line in target.split("\n"):
        if ":" in line:
            key, val = line.split(":", 1)
            out[key.strip()] = val.strip()
    return out


def split_full_row(r: Dict) -> Tuple[Dict, Dict]:
    """PS/FC row with a 5-line target -> (scope row, anchor row)."""
    t = _parse_target(r["target_text"])
    table = t.get("TARGET_TABLE") or r["target_table"]
    cmd = (t.get("TARGET_CMD") or r["target_cmd"]).upper()
    base = {"schema": r["schema"], "question": r["question"],
            "gold_table": table, "gold_cmd": cmd, "source": r.get("source", "")}
    scope = dict(base, stage="scope",
                 target_text=f"TARGET_TABLE: {table}\nTARGET_CMD: {cmd}")
    anchor = dict(base, stage="anchor",
                  target_text="\n".join(f"{k}: {t.get(k, '')}" for k in ANCHOR_KEYS))
    return scope, anchor


def load_auth_templates(path: str) -> List[Tuple[Dict, Dict]]:
    """Pair the scope and anchor rows of each template instantiation."""
    scope_by_q: Dict[str, Dict] = {}
    pairs: List[Tuple[Dict, Dict]] = []
    with open(path) as fh:
        for line in fh:
            r = json.loads(line)
            key = r["question"].strip()
            if r["stage"] == "scope":
                scope_by_q[key] = r
            elif key in scope_by_q:
                pairs.append((scope_by_q.pop(key), r))
    return pairs


def load_full_rows(path: str) -> List[Tuple[Dict, Dict]]:
    with open(path) as fh:
        return [split_full_row(json.loads(line)) for line in fh if line.strip()]


def main() -> None:
    p = argparse.ArgumentParser(description="Build the cascade supervision corpus D")
    p.add_argument("--auth-templates", required=True,
                   help="Authorization-Template JSONL from build_spider_auth.py")
    p.add_argument("--practical-structure", required=True)
    p.add_argument("--failure-cases", required=True)
    p.add_argument("--requirements", required=True,
                   help="RLSbench requirements.json (examples with the same NL are dropped)")
    p.add_argument("--out", required=True, help="Training split JSONL")
    p.add_argument("--dev-out", required=True, help="Development split JSONL")
    p.add_argument("--dev-frac", type=float, default=0.1)
    p.add_argument("--seed", type=int, default=42)
    args = p.parse_args()

    bench_nl = {_norm(r["requirement"]) for r in json.load(open(args.requirements))}

    sources = {
        "Authorization-Template": load_auth_templates(args.auth_templates),
        "Practical-Structure": load_full_rows(args.practical_structure),
        "Failure-Case": load_full_rows(args.failure_cases),
    }

    examples: List[Tuple[str, Dict, Dict]] = []
    dropped = Counter()
    for name, pairs in sources.items():
        for scope, anchor in pairs:
            if _norm(scope["question"]) in bench_nl:
                dropped[name] += 1
                continue
            examples.append((name, scope, anchor))

    rng = random.Random(args.seed)
    rng.shuffle(examples)
    n_dev = int(round(len(examples) * args.dev_frac))
    splits = {"dev": examples[:n_dev], "train": examples[n_dev:]}

    print(f"{'Source':<24} {'examples':>9} {'train':>7} {'dev':>6} {'dropped':>8}",
          file=sys.stderr)
    for name in sources:
        n_tr = sum(1 for s, _, _ in splits["train"] if s == name)
        n_dv = sum(1 for s, _, _ in splits["dev"] if s == name)
        print(f"{name:<24} {n_tr + n_dv:>9} {n_tr:>7} {n_dv:>6} {dropped[name]:>8}",
              file=sys.stderr)
    print(f"{'TOTAL':<24} {len(examples):>9} {len(splits['train']):>7} "
          f"{len(splits['dev']):>6} {sum(dropped.values()):>8}", file=sys.stderr)
    print("(each example = one scope row + one anchor row)", file=sys.stderr)

    for split, path in (("train", args.out), ("dev", args.dev_out)):
        out_path = Path(path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w") as fh:
            for _, scope, anchor in splits[split]:
                fh.write(json.dumps(scope) + "\n")
                fh.write(json.dumps(anchor) + "\n")
        print(f"Wrote {2 * len(splits[split])} rows to {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
