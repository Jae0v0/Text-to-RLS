"""Build gold table sets for each RLS policy.

Gold set for a policy = the ON target table  UNION  every table referenced
inside the policy predicate (read from o_attributes). Only prefixes that match
a real table in the schema are kept, so session variables (app.*) are dropped.

Output: gold_tables.json
  {"<id>": {"question": ..., "target": "schema.table",
            "gold_tables": ["schema.table", ...], "split": "train|dev|test"}}
"""
from __future__ import annotations

import argparse
import json
import logging
import re
from pathlib import Path
from typing import Dict, List, Set

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)

_ON_RE = re.compile(r"\bON\s+([A-Za-z_][\w]*\.[A-Za-z_][\w]*)", re.IGNORECASE)


def load_known_tables(tables_json: Path) -> Set[str]:
    data = json.loads(tables_json.read_text(encoding="utf-8"))
    return {t["table"] for t in data["tables"]}


def parse_target(sql: str) -> str | None:
    m = _ON_RE.search(sql)
    return m.group(1) if m else None


def tables_from_attributes(attrs: List[str], known: Set[str]) -> Set[str]:
    """Map o_attributes like 'hr.employees.is_active' -> 'hr.employees'."""
    out: Set[str] = set()
    for a in attrs:
        parts = a.split(".")
        if len(parts) >= 2:
            candidate = f"{parts[0]}.{parts[1]}"
            if candidate in known:
                out.add(candidate)
    return out


def build_split_index(splits: dict) -> Dict[int, str]:
    index: Dict[int, str] = {}
    for split in ("train", "dev", "test"):
        for pid in splits.get(split, []):
            index[int(pid)] = split
    return index


def main() -> None:
    here = Path(__file__).parent
    ap = argparse.ArgumentParser()
    ap.add_argument("--policies", default=str(here / "policies.json"))
    ap.add_argument("--splits", default=str(here / "policy_splits.json"))
    ap.add_argument("--tables", default=str(here / "outputs" / "tables.json"))
    ap.add_argument("--out", default=str(here / "outputs" / "gold_tables.json"))
    args = ap.parse_args()

    policies = json.loads(Path(args.policies).read_text(encoding="utf-8"))
    splits = json.loads(Path(args.splits).read_text(encoding="utf-8"))
    known = load_known_tables(Path(args.tables))
    split_of = build_split_index(splits)

    gold: Dict[str, dict] = {}
    missing_target = 0
    for rec in policies:
        pid = int(rec["id"])
        target = parse_target(rec["sql"])
        tabs: Set[str] = set()
        if target and target in known:
            tabs.add(target)
        elif target:
            missing_target += 1  # ON parsed but not a known table
        tabs |= tables_from_attributes(rec.get("o_attributes", []), known)
        gold[str(pid)] = {
            "question": rec["question"],
            "target": target,
            "gold_tables": sorted(tabs),
            "split": split_of.get(pid, "unknown"),
        }

    Path(args.out).write_text(json.dumps(gold, indent=2), encoding="utf-8")

    n_multi = sum(1 for g in gold.values() if len(g["gold_tables"]) > 1)
    by_split: Dict[str, int] = {}
    for g in gold.values():
        by_split[g["split"]] = by_split.get(g["split"], 0) + 1
    logger.info("policies: %d | multi-table gold: %d | targets unmatched: %d",
                len(gold), n_multi, missing_target)
    logger.info("by split: %s", by_split)


if __name__ == "__main__":
    main()
