"""Recompute every cell of the paper's main table (Table V) from the files in this directory.

Each row directory holds the model's predictions (predictions.json) and the executor output
(execution.json, produced by evaluation/run_test_cases.py on the 490 single-policy items).

Metric definitions (Eqs. (4)-(10) in Section III-D of the paper). All metrics are computed over
all 490 items. For item i, T_i is its reference test set in test_cases.json and u_i = 1 if the
predicted policy installs. A test of an item whose policy is missing or fails to install, or a test
that was not executed, counts as failed (v_i(t) = 0).
  PCS     sum u_i / 490
  BA      passed tests / all 3,100 tests
  OPR     1 - passed negative tests / all negative tests  (negative = negative, WITH CHECK, role mismatch)
  UPR     1 - passed positive tests / all positive tests
  Sec@0FP items whose negative and missing-session tests all pass / 490
  DDeny   passed missing-session tests / all missing-session tests
  IA      items whose tests all pass / 490
Values are rounded once, to three decimals.

Usage: python3 results/table_main/reproduce_table.py
Writes results/table_main/main_results.csv and prints any cell that differs from the paper.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
TESTS = HERE.parents[1] / "data/RLSbench/single_policy/test_cases.json"
NEG = ("negative", "role_mismatch", "with_check_negative")
MISS = "missing_session"
COLS = ["PCS", "BA", "OPR", "UPR", "Sec@0FP", "DDeny", "IA"]

# row directory -> (table label, setting, values printed in the paper)
PAPER = {
    "MAC-SQL_0shot": ("MAC-SQL", "0-shot", [.694, .462, .678, .742, .233, .638, .082]),
    "MAC-SQL_5shot": ("MAC-SQL", "5-shot", [.847, .638, .463, .679, .424, .824, .192]),
    "DAIL-SQL_0shot": ("DAIL-SQL", "0-shot", [.610, .461, .582, .765, .241, .571, .065]),
    "DAIL-SQL_5shot": ("DAIL-SQL", "5-shot", [.965, .763, .325, .540, .506, .935, .259]),
    "SQLCoder-7B-2_0shot": ("SQLCoder-7B-2", "0-shot", [.016, .010, .997, 1.000, .002, .018, .000]),
    "SQLCoder-7B-2_5shot": ("SQLCoder-7B-2", "5-shot", [.469, .336, .732, .841, .202, .449, .092]),
    "Qwen3-30B-A3B_0shot": ("Qwen3-30B-A3B (MoE)", "0-shot", [.665, .450, .665, .742, .237, .604, .073]),
    "Qwen3-30B-A3B_5shot": ("Qwen3-30B-A3B (MoE)", "5-shot", [.859, .646, .457, .669, .424, .833, .198]),
    "GLM-4-32B_0shot": ("GLM-4-32B", "0-shot", [.002, .001, .999, 1.000, .002, .002, .000]),
    "GLM-4-32B_5shot": ("GLM-4-32B", "5-shot", [.408, .298, .743, .890, .186, .394, .049]),
    "DeepSeek-V3.2_0shot": ("DeepSeek-V3.2", "0-shot", [.878, .637, .452, .571, .298, .776, .100]),
    "DeepSeek-V3.2_5shot": ("DeepSeek-V3.2", "5-shot", [.967, .771, .298, .542, .506, .931, .263]),
    "GPT-4.1_0shot": ("GPT-4.1", "0-shot", [.900, .703, .394, .568, .416, .870, .192]),
    "GPT-4.1_5shot": ("GPT-4.1", "5-shot", [.927, .747, .332, .540, .504, .906, .276]),
    "GPT-5.2_0shot": ("GPT-5.2", "0-shot", [.957, .698, .379, .789, .443, .925, .088]),
    "GPT-5.2_5shot": ("GPT-5.2", "5-shot", [.965, .776, .298, .554, .516, .946, .276]),
    "Gemini-3.1-Pro_0shot": ("Gemini-3.1-Pro", "0-shot", [.827, .620, .423, .722, .380, .771, .139]),
    "Gemini-3.1-Pro_5shot": ("Gemini-3.1-Pro", "5-shot", [.837, .661, .382, .624, .476, .793, .280]),
    "CARGO": ("CARGO", "5-shot", [.986, .884, .151, .319, .780, .981, .624]),
}


def metrics(execution: dict, gold: dict[int, list[str]]) -> list[float]:
    """Return the seven Table V metrics; `gold` maps item id -> purposes of its reference tests."""
    results = {it["id"]: it["test_results"] for it in execution["item_results"]}
    installed = [i for i in gold if results.get(i) and not all(
        (t.get("actual") or {}).get("outcome") == "harness_error" for t in results[i])]  # u_i = 1

    def passed(i: int, purposes: tuple) -> int:
        return sum(t["passed"] for t in results.get(i) or [] if t["purpose"] in purposes)

    def total(purposes: tuple) -> int:
        return sum(p in purposes for i in gold for p in gold[i])

    def all_pass(i: int, purposes: tuple) -> bool:
        ran = [t for t in results.get(i) or [] if t["purpose"] in purposes]
        return len(ran) == sum(p in purposes for p in gold[i]) and all(t["passed"] for t in ran)

    every = ("positive", *NEG, MISS)
    n = len(gold)
    return [
        len(installed) / n,
        sum(passed(i, every) for i in installed) / total(every),
        1 - sum(passed(i, NEG) for i in installed) / total(NEG),
        1 - sum(passed(i, ("positive",)) for i in installed) / total(("positive",)),
        sum(all_pass(i, NEG + (MISS,)) for i in installed) / n,
        sum(passed(i, (MISS,)) for i in installed) / total((MISS,)),
        sum(all_pass(i, every) for i in installed) / n,
    ]


def main() -> None:
    gold = {it["id"]: [t["purpose"] for t in it["test_cases"]] for it in json.loads(TESTS.read_text())}
    mismatches = 0
    with open(HERE / "main_results.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Model", "Setting", *COLS, "Directory"])
        for row, (label, setting, paper) in PAPER.items():
            got = [round(v, 3) for v in metrics(json.loads((HERE / row / "execution.json").read_text()), gold)]
            w.writerow([label, setting, *[f"{v:.3f}" for v in got], row])
            diff = [f"{c}: file {g:.3f} / paper {p:.3f}" for c, g, p in zip(COLS, got, paper) if abs(g - p) > 1e-9]
            mismatches += len(diff)
            print(f"{label:22s} {setting:7s} {'all 7 cells match' if not diff else '; '.join(diff)}")
    print(f"\n{len(PAPER)} rows x 7 cells, mismatches: {mismatches}  (test cases in denominator of BA: {sum(map(len, gold.values()))})")


if __name__ == "__main__":
    main()
