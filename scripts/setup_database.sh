#!/bin/bash
# setup_database.sh — build the clean RLSbench database (PostgreSQL 16).
#
# Usage:
#   ./scripts/setup_database.sh [DB_NAME]
#
# Default DB_NAME = rlsbench. Requires a running PostgreSQL 16 with the current user
# able to CREATE DATABASE. run_evaluation.sh never writes to this database: each
# evaluation runs on a fresh clone of it.

set -e
DB_NAME=${1:-rlsbench}
SCHEMA_FILE=data/RLSbench/schema/cleaned_schema.sql

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found — install PostgreSQL 16 first." >&2
  exit 1
fi

# (Re)create database
echo "=== Dropping/creating $DB_NAME ==="
psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -c "CREATE DATABASE $DB_NAME;"

# Load schema
echo "=== Loading schema from $SCHEMA_FILE ==="
psql -d "$DB_NAME" -f "$SCHEMA_FILE"

# Clock used by policies under test: the executor rewrites current_date, now(), ...
# to app_now(), which returns the test's mock time (app.now) or now() if unset.
psql -d "$DB_NAME" -c "
CREATE OR REPLACE FUNCTION public.app_now() RETURNS timestamptz
LANGUAGE sql STABLE AS
\$\$ SELECT COALESCE(NULLIF(current_setting('app.now', true), '')::timestamptz, now()) \$\$;"

# Enable RLS on every user table
echo "=== Enabling RLS on user tables ==="
psql -d "$DB_NAME" -tAc "
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog','information_schema');" | \
while IFS='|' read -r schema table; do
  psql -d "$DB_NAME" -c "ALTER TABLE $schema.$table ENABLE ROW LEVEL SECURITY;" >/dev/null
done

echo "Database $DB_NAME is ready. Runtime context variables:"
python3 -c "
import json
for v in json.load(open('data/RLSbench/schema/runtime_context/runtime_context_spec.json'))['variables']:
    print(f\"  - {v['name']:<24} ({v['type']})\")"
