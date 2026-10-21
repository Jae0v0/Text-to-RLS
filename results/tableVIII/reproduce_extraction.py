"""Recompute Table VIII and Fig. 4 of the paper from the files in this directory (490 items).

Table VIII: per-channel exact-set accuracy (%) of the scope (Table, Operation) and the anchors
(Run, Row, Env). Baselines are single 1-shot predictions; f_theta is oracle accuracy over its
top-3 cascade candidates (a channel counts as correct if any of the 3 candidates gets it right).
Fig. 4: oracle@K (K = 1..4) of Scope (Table and Operation both correct) and Anchor (Run, Row and
Env all correct) for the Standard (single-stage) and Cascaded extractors.
Also checks the top-1 scope accuracy quoted in Section IV-C (0.976).

Usage: python3 results/tableVIII/reproduce_extraction.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

HERE = Path(__file__).resolve().parent
COLS = ["Table", "Operation", "Run", "Row", "Env"]

# file -> (row label, values printed in Table VIII, top-K used)
TABLE8 = {
    "codes3b_base_1shot": ("CodeS-3B (1-shot, no FT)", [45.7, 87.8, 0.2, 2.0, 9.6], 1),
    "gpt41_1shot": ("GPT-4.1 (1-shot)", [93.9, 94.5, 0.6, 22.9, 57.8], 1),
    "qwen3_32b_1shot": ("Qwen3-30B-A3B (1-shot)", [78.0, 92.4, 0.6, 9.0, 28.0], 1),
    "extractor_cascaded_top8": ("Ours f_theta (oracle@3)", [99.0, 99.8, 96.9, 85.1, 97.8], 3),
}
# Fig. 4 points, K = 1..4 (also hard-coded in results/fig4/plot_scope_anchor_oracle_merged.py)
FIG4 = {
    ("extractor_normal_top8", "Scope"): [97.8, 98.2, 98.4, 98.4],
    ("extractor_cascaded_top8", "Scope"): [97.6, 98.4, 98.8, 99.8],
    ("extractor_normal_top8", "Anchor"): [72.7, 79.2, 81.8, 83.1],
    ("extractor_cascaded_top8", "Anchor"): [76.1, 81.6, 83.1, 83.3],
}
TOP1_SCOPE = 0.976


def load(name: str) -> List[dict]:
    return [json.loads(line) for line in (HERE / f"{name}.jsonl").open()]


def norm(x) -> List[str]:
    return sorted(set(x or []))


def channels(c: dict, g: dict) -> List[bool]:
    return [c.get("pred_table") == g["gold_table"], c.get("pred_cmd") == g["gold_cmd"],
            norm(c.get("pred_s")) == norm(g["gold_s"]), norm(c.get("pred_o")) == norm(g["gold_o"]),
            norm(c.get("pred_e")) == norm(g["gold_e"])]


def top(r: dict, k: int) -> List[dict]:
    return sorted(r["candidates"], key=lambda c: c["rank"])[:k] if "candidates" in r else [r]


def pct(rows: List[dict], hit) -> float:
    return round(100 * sum(hit(r) for r in rows) / len(rows), 1)


def main() -> None:
    mismatches = 0
    print("Table VIII")
    for name, (label, paper, k) in TABLE8.items():
        rows = load(name)
        assert len(rows) == 490, (name, len(rows))
        got = [pct(rows, lambda r, j=j: any(channels(c, r)[j] for c in top(r, k))) for j in range(5)]
        diff = [f"{c}: file {g} / paper {p}" for c, g, p in zip(COLS, got, paper) if g != p]
        mismatches += len(diff)
        print(f"  {label:26s} {'all 5 cells match' if not diff else '; '.join(diff)}")

    print("Fig. 4 (oracle@K, K = 1..4)")
    for (name, kind), paper in FIG4.items():
        rows = load(name)
        if kind == "Scope":
            hit = lambda c, r: channels(c, r)[0] and channels(c, r)[1]
        else:
            hit = lambda c, r: all(channels(c, r)[2:])
        got = [pct(rows, lambda r, k=k: any(hit(c, r) for c in top(r, k))) for k in range(1, 5)]
        ok = got == paper
        mismatches += 0 if ok else 1
        tag = "Standard" if "normal" in name else "Cascaded"
        print(f"  {tag:8s} {kind:6s} {got} {'match' if ok else f'paper {paper}'}")

    rows = load("extractor_cascaded_top8")
    top1 = round(sum(channels(top(r, 1)[0], r)[0] and channels(top(r, 1)[0], r)[1] for r in rows) / len(rows), 3)
    mismatches += top1 != TOP1_SCOPE
    print(f"Top-1 scope accuracy of f_theta: {top1} (paper {TOP1_SCOPE})")
    print(f"\nmismatches: {mismatches}")


if __name__ == "__main__":
    main()
