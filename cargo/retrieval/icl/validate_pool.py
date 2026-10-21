"""Keep the demonstration-pool entries whose policy installs on the target schema.

Each enterprise-schema entry's CREATE POLICY statement is executed inside a
savepoint on a database built by scripts/setup_database.sh and rolled back;
entries that raise an error are dropped (paper §IV-D, "each enterprise entry
passes a CREATE POLICY round trip"). Supabase and PostgREST examples (entries
with a source_url) target their own schemas and are kept verbatim.

Usage:
    python3 cargo/retrieval/icl/validate_pool.py \
        --kb cargo/retrieval/icl/kb_practical_structure.json \
        --db_name rlsbench --out kb_validated.json
"""
from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path

import psycopg2

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--db_host", default=os.environ.get("PGHOST", "localhost"))
    ap.add_argument("--db_port", type=int, default=int(os.environ.get("PGPORT", 5432)))
    ap.add_argument("--db_user", default=os.environ.get("PGUSER", "postgres"))
    ap.add_argument("--db_pass", default=os.environ.get("PGPASSWORD", "postgres"))
    ap.add_argument("--db_name", default="rlsbench")
    args = ap.parse_args()

    kb = json.loads(Path(args.kb).read_text())
    conn = psycopg2.connect(host=args.db_host, port=args.db_port, user=args.db_user,
                            password=args.db_pass, dbname=args.db_name)
    kept, failed = [], []
    with conn.cursor() as cur:
        for entry in kb:
            if "source_url" in entry:          # Supabase / PostgREST example, own schema
                kept.append(entry)
                continue
            cur.execute("SAVEPOINT kb_check")
            try:
                cur.execute(entry["sql"])
                kept.append(entry)
            except psycopg2.Error as e:
                failed.append((entry["id"], str(e).splitlines()[0]))
            cur.execute("ROLLBACK TO SAVEPOINT kb_check")
    conn.rollback()
    conn.close()

    Path(args.out).write_text(json.dumps(kept, ensure_ascii=False, indent=1))
    logger.info("kept %d / %d entries -> %s", len(kept), len(kb), args.out)
    for eid, msg in failed[:20]:
        logger.info("  dropped %s: %s", eid, msg)


if __name__ == "__main__":
    main()
