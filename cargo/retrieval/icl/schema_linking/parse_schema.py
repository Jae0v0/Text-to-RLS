"""Parse the Text2RLS SQL schema into per-table records and a compact catalog.

Input : a PostgreSQL dump (CREATE TABLE statements).
Output: tables.json  -> {"tables": [{"table": "hr.employees", "schema": "hr",
                                      "name": "employees", "columns": [...]}, ...]}
        catalog.txt  -> one line per table: "schema.table(col1, col2, ...)"

The catalog is the shared context handed to the LLM retriever.
"""
from __future__ import annotations

import argparse
import json
import logging
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# Lines inside a CREATE TABLE block that are constraints, not columns.
_NON_COLUMN_PREFIXES = (
    "CONSTRAINT", "PRIMARY", "FOREIGN", "UNIQUE", "CHECK", "EXCLUDE",
)
_CREATE_RE = re.compile(r"CREATE TABLE\s+([A-Za-z_][\w]*\.[A-Za-z_][\w]*)\s*\(", re.IGNORECASE)


@dataclass(frozen=True)
class Table:
    table: str          # "schema.name"
    schema: str
    name: str
    columns: List[str]


def _strip_quotes(token: str) -> str:
    return token.strip().strip('"')


def _parse_column_name(line: str) -> str | None:
    """Return the column name from a column-definition line, or None."""
    stripped = line.strip().rstrip(",")
    if not stripped:
        return None
    upper = stripped.upper()
    if any(upper.startswith(p) for p in _NON_COLUMN_PREFIXES):
        return None
    # First token is the column name; it may be quoted (e.g. "current_role").
    if stripped.startswith('"'):
        end = stripped.find('"', 1)
        if end == -1:
            return None
        return stripped[1:end]
    return _strip_quotes(stripped.split()[0])


def parse_schema(sql_text: str) -> List[Table]:
    """Extract all tables and their column names from a SQL dump."""
    tables: List[Table] = []
    for match in _CREATE_RE.finditer(sql_text):
        full = match.group(1)
        schema, name = full.split(".", 1)
        # Body runs from after "(" to the matching ");" at line start.
        body = sql_text[match.end():]
        end = body.find("\n);")
        if end == -1:
            end = body.find(");")
        body = body[:end]
        columns: List[str] = []
        for line in body.splitlines():
            col = _parse_column_name(line)
            if col:
                columns.append(col)
        tables.append(Table(table=full, schema=schema, name=name, columns=columns))
    return tables


def build_catalog(tables: List[Table]) -> str:
    """One line per table: schema.table(col1, col2, ...)."""
    lines = [f"{t.table}({', '.join(t.columns)})" for t in tables]
    return "\n".join(lines)


def main() -> None:
    here = Path(__file__).parent
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", default=str(here / "cleaned_text2rls_schema.sql"))
    ap.add_argument("--out-dir", default=str(here / "outputs"))
    args = ap.parse_args()

    sql_text = Path(args.schema).read_text(encoding="utf-8")
    tables = parse_schema(sql_text)
    logger.info("Parsed %d tables", len(tables))

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "tables.json").write_text(
        json.dumps({"tables": [asdict(t) for t in tables]}, indent=2),
        encoding="utf-8",
    )
    catalog = build_catalog(tables)
    (out_dir / "catalog.txt").write_text(catalog, encoding="utf-8")
    logger.info("catalog.txt: %d chars (~%d tokens)", len(catalog), len(catalog) // 4)


if __name__ == "__main__":
    main()
