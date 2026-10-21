"""Few-shot prompt construction for the LLM table retriever.

The base Llama-3.1-8B has no chat template, so we use plain completion with
in-context demonstrations drawn from the train split.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List

_INSTRUCTION = (
    "You are a schema linker for database row-level security (RLS) policies.\n"
    "Below is the database catalog. Each line is one table as "
    "schema.table(column, column, ...).\n\n"
    "{catalog}\n\n"
    "Task: given a natural-language policy description, output ONLY the tables "
    "needed to express that policy, as a comma-separated list of schema.table "
    "names taken from the catalog. Output nothing else.\n"
)


@dataclass(frozen=True)
class Demo:
    question: str
    tables: List[str]


def select_demos(gold: Dict[str, dict], k: int = 8) -> List[Demo]:
    """Pick k diverse train demos: distinct targets, include multi-table cases.

    Deterministic: iterate train ids in ascending order, prefer unseen target
    tables, and ensure at least a couple of multi-table examples are present.
    """
    train = sorted(
        ((int(pid), g) for pid, g in gold.items() if g["split"] == "train"),
        key=lambda x: x[0],
    )
    demos: List[Demo] = []
    seen_targets: set = set()

    # Pass 1: multi-table examples first (rarer, more informative).
    for _, g in train:
        if len(demos) >= max(2, k // 4):
            break
        if len(g["gold_tables"]) > 1:
            demos.append(Demo(g["question"], g["gold_tables"]))
            seen_targets.add(g["target"])

    # Pass 2: fill with distinct single-table targets.
    for _, g in train:
        if len(demos) >= k:
            break
        if g["target"] in seen_targets:
            continue
        demos.append(Demo(g["question"], g["gold_tables"]))
        seen_targets.add(g["target"])

    return demos[:k]


def render_demo(question: str, tables: List[str]) -> str:
    return f"Description: {question}\nTables: {', '.join(tables)}"


def build_prompt(catalog: str, demos: List[Demo], question: str) -> str:
    parts = [_INSTRUCTION.format(catalog=catalog), ""]
    for d in demos:
        parts.append(render_demo(d.question, d.tables))
        parts.append("")
    parts.append(f"Description: {question}\nTables:")
    return "\n".join(parts)
