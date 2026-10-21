"""Recompute the component ablation (Table VI) and the generator-backbone table (Table VII).

Each directory holds the model's predictions (predictions.json) and the executor output
(execution.json, produced by evaluation/run_test_cases.py on the 490 single-policy items).
Two rows reuse the main table: the component baseline is DeepSeek-V3.2 5-shot and the full
CARGO row is CARGO (results/table_main/). The DeepSeek-V3.2 backbone row is the +G row.
Metrics follow Eqs. (4)-(10) of the paper and are computed by results/table_main/reproduce_table.py.

Usage: python3 results/ablation/reproduce_ablation.py
Prints every cell that differs from the paper.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAIN = HERE.parent / "table_main"
sys.path.insert(0, str(MAIN))
from reproduce_table import TESTS, metrics  # noqa: E402

COLS = ["PCS", "BA", "OPR", "UPR", "Sec@0FP", "DDeny", "IA"]

# (table, row label, execution file, {column: value printed in the paper})
ROWS = [
    ("VI", "Baseline", MAIN / "DeepSeek-V3.2_5shot", {"BA": .771, "OPR": .298, "Sec@0FP": .506, "DDeny": .931, "IA": .263}),
    ("VI", "+G", HERE / "G_operation_routed_icl", {"BA": .822, "OPR": .246, "Sec@0FP": .641, "DDeny": .961, "IA": .457}),
    ("VI", "+X+G", HERE / "XG_extractor_plus_icl", {"BA": .879, "OPR": .160, "Sec@0FP": .771, "DDeny": .980, "IA": .604}),
    ("VI", "CARGO (full)", MAIN / "CARGO", {"BA": .884, "OPR": .151, "Sec@0FP": .780, "DDeny": .981, "IA": .624}),
    ("VII", "GPT-4.1", HERE / "backbone_GPT-4.1", {"BA": .797, "PCS": .943, "OPR": .253, "Sec@0FP": .657, "IA": .439}),
    ("VII", "GPT-5.2", HERE / "backbone_GPT-5.2", {"BA": .797, "PCS": .955, "OPR": .270, "Sec@0FP": .643, "IA": .443}),
    ("VII", "DeepSeek-V3.2", HERE / "G_operation_routed_icl", {"BA": .822, "PCS": .971, "OPR": .246, "Sec@0FP": .641, "IA": .457}),
    ("VII", "Qwen3-30B-A3B", HERE / "backbone_Qwen3-30B", {"BA": .795, "PCS": .963, "OPR": .277, "Sec@0FP": .618, "IA": .398}),
]


def main() -> None:
    gold = {it["id"]: [t["purpose"] for t in it["test_cases"]] for it in json.loads(TESTS.read_text())}
    mismatches = 0
    for table, label, row_dir, paper in ROWS:
        got = dict(zip(COLS, (round(v, 3) for v in metrics(json.loads((row_dir / "execution.json").read_text()), gold))))
        diff = [f"{c}: file {got[c]:.3f} / paper {p:.3f}" for c, p in paper.items() if abs(got[c] - p) > 1e-9]
        mismatches += len(diff)
        print(f"Table {table:3s} {label:14s} {'all cells match' if not diff else '; '.join(diff)}")
    print(f"\n{len(ROWS)} rows, mismatches: {mismatches}")


if __name__ == "__main__":
    main()
