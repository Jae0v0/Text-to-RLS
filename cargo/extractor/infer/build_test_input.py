"""Build the extractor input for RLSbench items (one JSONL row per evaluated item).

Each row carries the requirement N, the schema Sigma in the compact format the
extractor is trained on ("# table: col1, col2, ..."), and the gold scope and
anchors (used only to report extraction accuracy).

Usage:
  python3 cargo/extractor/infer/build_test_input.py \
    --policies data/RLSbench/single_policy/policies.json \
    --test-cases data/RLSbench/single_policy/test_cases.json \
    --schema data/RLSbench/schema/trimmed_schema.sql \
    --out data/test_text2rls.jsonl
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List

_TABLE_RE = re.compile(r"CREATE TABLE (?:IF NOT EXISTS )?(\w+\.\w+)\s*\((.*?)\n\);", re.S)
_SKIP_RE = re.compile(r"(CONSTRAINT|PRIMARY KEY|FOREIGN KEY|UNIQUE|CHECK|--)", re.I)


def parse_ddl(ddl: str) -> Dict[str, List[str]]:
    """{schema.table: [columns]} from CREATE TABLE statements."""
    tables: Dict[str, List[str]] = {}
    for name, body in _TABLE_RE.findall(ddl):
        cols = []
        for line in body.split("\n"):
            line = line.strip()
            if line and not _SKIP_RE.match(line):
                cols.append(line.split()[0].strip('"'))
        tables[name] = cols
    return tables


def compact_schema(tables: Dict[str, List[str]]) -> str:
    return "\n".join(f"# {t}: {', '.join(cols)}" for t, cols in tables.items())


def policy_scope(sql: str) -> Dict[str, str]:
    table = re.search(r"\bON\s+([\w.]+)", sql, re.I).group(1)
    cmd = re.search(r"\bFOR\s+(ALL|SELECT|INSERT|UPDATE|DELETE)\b", sql, re.I)
    return {"table": table, "cmd": cmd.group(1).upper() if cmd else "ALL"}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--policies", required=True)
    ap.add_argument("--test-cases", required=True,
                    help="items with test cases define the evaluated set")
    ap.add_argument("--schema", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    schema = compact_schema(parse_ddl(Path(args.schema).read_text()))
    eval_ids = {it["id"] for it in json.loads(Path(args.test_cases).read_text())}
    policies = [p for p in json.loads(Path(args.policies).read_text()) if p["id"] in eval_ids]

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w") as fh:
        for p in policies:
            scope = policy_scope(p["sql"])
            fh.write(json.dumps({
                "id": p["id"],
                "question": p["question"],
                "schema": schema,
                "gold_table": scope["table"],
                "action": scope["cmd"],
                "s_attributes": p.get("s_attributes", []),
                "o_attributes": p.get("o_attributes", []),
                "e_attributes": p.get("e_attributes", []),
                "difficulty": p.get("difficulty"),
                "attribute_pattern": p.get("attribute_pattern"),
            }) + "\n")
    print(f"wrote {len(policies)} items to {out}")


if __name__ == "__main__":
    main()
