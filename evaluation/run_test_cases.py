"""Execution-based evaluator for text2RLS benchmark.

Loads test_cases.json, connects to PostgreSQL, and runs each test case
by creating the gold/predicted policy, inserting seed rows, setting session
variables, executing the action SQL, and comparing the result against
expected outcomes.

Usage (from the repository root):
    python3 evaluation/run_test_cases.py --mode pred \
        --test_cases_path data/RLSbench/single_policy/test_cases.json \
        --benchmark_path data/RLSbench/single_policy/policies.json \
        --predictions_path predictions.json \
        --db_host localhost --db_port 5432 --db_user postgres --db_pass postgres \
        --db_name rlsbench \
        --output_path eval_results.json

Modes:
    --mode gold    Run gold SQL policies (validate test harness)
    --mode pred    Run predicted SQL policies (evaluate model)
"""

import argparse
import os
import json
import logging
import re
import sys
import traceback
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional, Tuple

import psycopg2
from psycopg2 import sql as pgsql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# TABLE_PK_MAP is defined in the benchmark's test-case generator.
sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "data", "RLSbench",
    "multi_policy", "tools",
))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Override with RLS_TEST_ROLE to run several evaluations in parallel on different
# databases without concurrent updates to one cluster-wide role.
TEST_ROLE = os.environ.get("RLS_TEST_ROLE", "rls_test_user")
TEST_ROLE_PASSWORD = "test_password"

# All known session attributes — must be RESET before each test
# to prevent GUC leaking from prior SET LOCAL operations
ALL_SESSION_ATTRS = [
    "app.employee_id", "app.user_id", "app.customer_id", "app.job_role",
    "app.department_id", "app.team_id", "app.region_id", "app.tenant_id",
    "app.position_level", "app.user_clearance_level", "app.approval_limit",
    "app.user_type", "app.is_team_lead", "app.hire_date",
    "app.project_id", "app.current_workload_hours", "app.team_avg_workload_hours",
    "app.warehouse_id", "app.monthly_allowance", "app.daily_export_quota",
    "app.batch_account_id", "app.partner_id", "app.security_clearance",
    "app.now",
]

# Default values for NOT NULL columns without defaults (by data type)
_TYPE_DEFAULTS = {
    "integer": 0,
    "bigint": 0,
    "smallint": 0,
    "numeric": 0,
    "real": 0.0,
    "double precision": 0.0,
    "text": "",
    "character varying": "",
    "boolean": False,
    "date": "2025-01-01",
    "time without time zone": "09:00:00",
    "timestamp without time zone": "2025-01-01 00:00:00",
    "timestamp with time zone": "2025-01-01 00:00:00+00",
    "ARRAY": "{}",
}


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

# A statement that runs longer than this (e.g. a recursive policy over cyclic data)
# is aborted; the test then fails like any other execution error.
STATEMENT_TIMEOUT_OPTION = "-c statement_timeout=60000"


def get_connection(args: argparse.Namespace):
    """Create a psycopg2 connection."""
    return psycopg2.connect(
        host=args.db_host,
        port=args.db_port,
        user=args.db_user,
        password=args.db_pass,
        dbname=args.db_name,
        options=STATEMENT_TIMEOUT_OPTION,
    )


def ensure_test_role(conn) -> None:
    """Create the test role and grant membership in 'authenticated'."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = %s", (TEST_ROLE,)
        )
        if not cur.fetchone():
            cur.execute(
                pgsql.SQL("CREATE ROLE {} LOGIN NOSUPERUSER NOBYPASSRLS PASSWORD %s").format(
                    pgsql.Identifier(TEST_ROLE)
                ), (TEST_ROLE_PASSWORD,)
            )
            logger.info("Created test role: %s", TEST_ROLE)
        else:
            # Ensure password is set (tolerate concurrent ALTER from parallel workers)
            try:
                cur.execute(f"ALTER ROLE {TEST_ROLE} WITH NOSUPERUSER NOBYPASSRLS PASSWORD %s",
                            (TEST_ROLE_PASSWORD,))
            except Exception:
                conn.rollback()

        # Grant authenticated role if it exists (policies use TO authenticated)
        cur.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = 'authenticated'"
        )
        if cur.fetchone():
            cur.execute(
                f"GRANT authenticated TO {TEST_ROLE}"
            )
            logger.info("Granted 'authenticated' to %s", TEST_ROLE)

        # Grant SELECT on every user-schema table so EXISTS subqueries that
        # reference tables other than the policy target (e.g. auth.tenants,
        # hr.employee_allowances) can be read by the test role.
        cur.execute(
            """
            SELECT nspname FROM pg_namespace
            WHERE nspname NOT IN ('pg_catalog','information_schema','pg_toast')
              AND nspname NOT LIKE 'pg_temp%' AND nspname NOT LIKE 'pg_toast%'
            """
        )
        for (schema,) in cur.fetchall():
            try:
                cur.execute(
                    pgsql.SQL("GRANT USAGE ON SCHEMA {} TO {}").format(
                        pgsql.Identifier(schema), pgsql.Identifier(TEST_ROLE)
                    )
                )
                cur.execute(
                    pgsql.SQL(
                        "GRANT SELECT ON ALL TABLES IN SCHEMA {} TO {}"
                    ).format(
                        pgsql.Identifier(schema), pgsql.Identifier(TEST_ROLE)
                    )
                )
            except Exception:
                conn.rollback()
        logger.info("Granted cross-schema SELECT to %s", TEST_ROLE)


def grant_table_access(conn, table: str) -> None:
    """Grant SELECT/INSERT/UPDATE/DELETE on a table to the test role."""
    schema, tbl = table.split(".", 1)
    with conn.cursor() as cur:
        cur.execute(
            pgsql.SQL("GRANT USAGE ON SCHEMA {} TO {}").format(
                pgsql.Identifier(schema), pgsql.Identifier(TEST_ROLE)
            )
        )
        cur.execute(
            pgsql.SQL("GRANT SELECT, INSERT, UPDATE, DELETE ON {} TO {}").format(
                pgsql.SQL(table), pgsql.Identifier(TEST_ROLE)
            )
        )
    conn.commit()


def get_not_null_columns(conn, table: str) -> Dict[str, str]:
    """Get NOT NULL columns without defaults for a table.

    Returns dict mapping column_name → data_type.
    """
    schema, tbl = table.split(".", 1)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = %s AND table_name = %s
              AND is_nullable = 'NO' AND column_default IS NULL
        """, (schema, tbl))
        return {row[0]: row[1] for row in cur.fetchall()}


def get_all_columns(conn, table: str) -> Dict[str, str]:
    """Get all columns for a table. Returns dict mapping name → data_type."""
    schema, tbl = table.split(".", 1)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = %s AND table_name = %s
            ORDER BY ordinal_position
        """, (schema, tbl))
        return {row[0]: row[1] for row in cur.fetchall()}


# ---------------------------------------------------------------------------
# Seed row insertion
# ---------------------------------------------------------------------------

def validate_seed_row(
    seed_row: Dict[str, Any],
    all_columns: Dict[str, str],
) -> Dict[str, Any]:
    """Remove non-existent columns and fix type mismatches in seed row.

    Args:
        seed_row: Column→value mapping from the generator.
        all_columns: Actual column→data_type mapping from the DB.

    Returns:
        Cleaned row with only valid columns and type-compatible values.
    """
    _INT_TYPES = {"integer", "bigint", "smallint"}
    _FLOAT_TYPES = {"numeric", "real", "double precision"}
    _TS_TYPES = {"timestamp without time zone", "timestamp with time zone"}
    _BOOL_TYPES = {"boolean"}

    row = {}
    for col, val in seed_row.items():
        if col not in all_columns:
            # Column doesn't exist in actual table — skip it
            continue
        dtype = all_columns[col]

        # An explicit JSON null is semantically meaningful in RLS fixtures
        # (for example ``assignee_id IS NULL``).  It must not be coerced to a
        # type default; missing NOT NULL values are filled in the next phase.
        if val is None:
            row[col] = None
            continue

        # Fix type mismatches
        if dtype in _INT_TYPES:
            if isinstance(val, (int, float)):
                row[col] = int(val)
            elif isinstance(val, str):
                try:
                    row[col] = int(val)
                except ValueError:
                    # String in integer column (e.g. "app.employee_id",
                    # "2025-01-01 00:00:00", "some_value") → use 1
                    row[col] = 1
            elif isinstance(val, bool):
                row[col] = 1 if val else 0
            else:
                row[col] = 1
        elif dtype in _FLOAT_TYPES:
            if isinstance(val, (int, float)):
                row[col] = float(val)
            elif isinstance(val, str):
                try:
                    row[col] = float(val)
                except ValueError:
                    row[col] = 1.0
            else:
                row[col] = 1.0
        elif dtype in _BOOL_TYPES:
            if isinstance(val, bool):
                row[col] = val
            elif isinstance(val, str):
                row[col] = val.lower() in ("true", "t", "1", "yes")
            else:
                row[col] = bool(val)
        elif dtype == "date":
            if isinstance(val, (int, float)):
                row[col] = "2025-01-01"
            elif isinstance(val, str) and " " in val:
                # Timestamp string in date column → take date part
                row[col] = val.split(" ")[0]
            elif isinstance(val, str):
                import re as _re
                if _re.match(r"\d{4}-\d{2}-\d{2}", val):
                    row[col] = val
                else:
                    row[col] = "2025-01-01"
            else:
                row[col] = val
        elif dtype in _TS_TYPES:
            if isinstance(val, (int, float)):
                # Integer in timestamp column → use default timestamp
                row[col] = "2025-01-01 00:00:00"
            elif isinstance(val, str):
                # Validate it looks like a date/timestamp
                import re as _re
                if _re.match(r"\d{4}-\d{2}-\d{2}", val):
                    row[col] = val
                else:
                    row[col] = "2025-01-01 00:00:00"
            else:
                row[col] = val
        elif dtype == "ARRAY":
            if isinstance(val, str) and not val.startswith("{"):
                row[col] = "{" + val + "}"
            else:
                row[col] = val if val else "{}"
        else:
            row[col] = val
    return row


def get_check_fill_values(conn, table: str) -> Dict[str, Any]:
    """Derive constraint-valid fill values for columns under CHECK constraints.

    Handles two common shapes so auto-filled NOT NULL columns don't violate
    domain/range checks during seed insertion:
      - domain list:  (lower(col) = ANY (ARRAY['a','b',...]))  -> first literal
      - lower bound:  (col >= N ...)                           -> N
    """
    schema, tbl = table.split(".", 1)
    out: Dict[str, Any] = {}
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT pg_get_constraintdef(c.oid)
            FROM pg_constraint c
            JOIN pg_class r ON r.oid = c.conrelid
            JOIN pg_namespace n ON n.oid = r.relnamespace
            WHERE c.contype = 'c' AND n.nspname = %s AND r.relname = %s
            """,
            (schema, tbl),
        )
        defs = [row[0] for row in cur.fetchall()]
    for d in defs:
        m = re.search(r"lower\(\(?(\w+)\)?[^)]*\)\s*=\s*ANY\s*\(ARRAY\[([^\]]+)\]", d)
        if m:
            col = m.group(1)
            lits = re.findall(r"'([^']+)'", m.group(2))
            if lits and col not in out:
                out[col] = lits[0]
            continue
        m = re.search(r"\((\w+)\s*>=\s*\(?(-?\d+)", d)
        if m:
            col, lo = m.group(1), int(m.group(2))
            if col not in out:
                out[col] = lo
    return out


def fill_required_columns(
    seed_row: Dict[str, Any],
    required: Dict[str, str],
    check_values: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Fill in any NOT NULL columns missing from the seed row.

    check_values supplies constraint-valid defaults for columns under domain/
    range CHECK constraints so seed insertion does not fail on auto-fill.
    """
    check_values = check_values or {}
    row = dict(seed_row)
    for col, dtype in required.items():
        if col not in row:
            if col in check_values:
                row[col] = check_values[col]
            else:
                row[col] = _TYPE_DEFAULTS.get(dtype, "")
    return row


def insert_seed_row(cur, table: str, row: Dict[str, Any]) -> None:
    """Insert a single seed row into a table."""
    if not row:
        return
    cols = list(row.keys())
    vals = list(row.values())
    col_str = ", ".join(pgsql.Identifier(c).as_string(cur) for c in cols)
    placeholders = ", ".join(["%s"] * len(vals))
    cur.execute(
        f"INSERT INTO {table} ({col_str}) VALUES ({placeholders})",
        vals,
    )


# ---------------------------------------------------------------------------
# Policy management
# ---------------------------------------------------------------------------

def enable_rls(cur, table: str) -> None:
    """Enable RLS on a table and force it for the table owner too."""
    cur.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY")
    cur.execute(f"ALTER TABLE {table} FORCE ROW LEVEL SECURITY")


def disable_rls(cur, table: str) -> None:
    """Disable RLS on a table."""
    cur.execute(f"ALTER TABLE {table} DISABLE ROW LEVEL SECURITY")


def snapshot_rls_state(cur) -> Tuple[set, Dict[str, Tuple[bool, bool]]]:
    """Record every policy and every table's RLS flags before a test.

    A predicted policy may target a table other than the test's target table;
    restore_rls_state() removes such policies so no test affects a later one.
    """
    cur.execute("SELECT schemaname, tablename, policyname FROM pg_policies")
    policies = {tuple(r) for r in cur.fetchall()}
    cur.execute(
        "SELECT n.nspname || '.' || c.relname, c.relrowsecurity, c.relforcerowsecurity "
        "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
        "WHERE c.relkind IN ('r', 'p') "
        "AND n.nspname NOT IN ('pg_catalog', 'information_schema')"
    )
    flags = {name: (bool(rls), bool(force)) for name, rls, force in cur.fetchall()}
    return policies, flags


def restore_rls_state(cur, snapshot) -> None:
    """Drop policies created since the snapshot and restore RLS flags."""
    if snapshot is None:
        return
    policies, flags = snapshot
    cur.execute("SELECT schemaname, tablename, policyname FROM pg_policies")
    for schema, tbl, name in cur.fetchall():
        if (schema, tbl, name) not in policies:
            cur.execute(
                pgsql.SQL("DROP POLICY IF EXISTS {} ON {}.{}").format(
                    pgsql.Identifier(name), pgsql.Identifier(schema), pgsql.Identifier(tbl)
                )
            )
    _, now = snapshot_rls_state(cur)
    for name, (rls, force) in flags.items():
        if now.get(name, (rls, force)) == (rls, force):
            continue
        schema, tbl = name.split(".", 1)
        target = pgsql.SQL("{}.{}").format(pgsql.Identifier(schema), pgsql.Identifier(tbl))
        cur.execute(pgsql.SQL("ALTER TABLE {} {} ROW LEVEL SECURITY").format(
            target, pgsql.SQL("ENABLE" if rls else "DISABLE")))
        cur.execute(pgsql.SQL("ALTER TABLE {} {} ROW LEVEL SECURITY").format(
            target, pgsql.SQL("FORCE" if force else "NO FORCE")))


def drop_all_policies(cur, table: str) -> None:
    """Drop all existing policies on a table."""
    schema, tbl = table.split(".", 1)
    cur.execute("""
        SELECT policyname FROM pg_policies
        WHERE schemaname = %s AND tablename = %s
    """, (schema, tbl))
    for row in cur.fetchall():
        cur.execute(
            pgsql.SQL("DROP POLICY IF EXISTS {} ON {}.{}").format(
                pgsql.Identifier(row[0]),
                pgsql.Identifier(schema),
                pgsql.Identifier(tbl),
            )
        )


# Clock functions are evaluated at the test's mock time: every way of reading the
# current date/time is rewritten to app_now(), which returns the test's mock_time
# (or NOW() when a test has none). Applied to every policy, reference or predicted,
# so results do not depend on when the tests are run.
_CLOCK_REWRITES = [
    (re.compile(r"\bcurrent_timestamp(\s*\(\s*\d+\s*\))?", re.I), "app_now()"),
    (re.compile(r"\b(?:transaction_timestamp|statement_timestamp|clock_timestamp|now)\s*\(\s*\)", re.I), "app_now()"),
    (re.compile(r"\blocaltimestamp(\s*\(\s*\d+\s*\))?", re.I), "app_now()::timestamp"),
    (re.compile(r"\bcurrent_date\b", re.I), "app_now()::date"),
    (re.compile(r"\bcurrent_time\b(\s*\(\s*\d+\s*\))?", re.I), "app_now()::time"),
    (re.compile(r"\blocaltime\b(\s*\(\s*\d+\s*\))?", re.I), "app_now()::time"),
]


def pin_clock_to_mock_time(policy_sql: str) -> str:
    """Rewrite clock functions outside string literals to app_now()."""
    parts = re.split(r"('(?:[^']|'')*')", policy_sql)
    for i in range(0, len(parts), 2):
        for pattern, repl in _CLOCK_REWRITES:
            parts[i] = pattern.sub(repl, parts[i])
    return "".join(parts)


def create_policy(cur, policy_sql: str) -> None:
    """Execute a CREATE POLICY statement with clock functions pinned to the mock time."""
    cur.execute(pin_clock_to_mock_time(policy_sql))


# ---------------------------------------------------------------------------
# Session management
# ---------------------------------------------------------------------------

def set_session_vars(cur, session: Dict[str, str], local: bool = True) -> None:
    """Set session variables via SET LOCAL (transaction-scoped) or SET.

    SET LOCAL is automatically undone on ROLLBACK, solving session leak.
    """
    prefix = "SET LOCAL" if local else "SET"
    for key, val in session.items():
        cur.execute(f"{prefix} {key} = %s", (str(val),))


def reset_session_vars(cur, session: Dict[str, str]) -> None:
    """Reset session variables."""
    for key in session:
        cur.execute(f"RESET {key}")


# ---------------------------------------------------------------------------
# Test execution
# ---------------------------------------------------------------------------

@dataclass
class TestResult:
    """Result of a single test case execution."""
    case_id: str
    purpose: str
    passed: bool
    expected: Dict[str, Any]
    actual: Dict[str, Any]
    error: Optional[str] = None
    category: str = ""


def _business_hours_timezone(policy_sql: str = "") -> str:
    """Return a timezone name where current_time falls in the policy time range.

    Detects time range patterns in the policy and targets the midpoint hour.
    Handles: BETWEEN [TIME] 'HH:MM' AND [TIME] 'HH:MM', comparison operators,
    and outside-hours patterns (< TIME OR >= TIME).
    Also ensures DOW is a weekday (Mon-Fri) if the policy checks DOW.
    Falls back to noon (12:00) if no time range is found.
    """
    import datetime

    target_hour = None

    # Pattern 1: BETWEEN [TIME] 'HH:MM'[::time] AND [TIME] 'HH:MM'[::time]
    m = re.search(
        r"BETWEEN\s+(?:TIME\s+)?'(\d{1,2}):(\d{2})'(?:::time)?\s+AND\s+(?:TIME\s+)?'(\d{1,2}):(\d{2})'",
        policy_sql, re.IGNORECASE,
    )
    if m:
        start_h, end_h = int(m.group(1)), int(m.group(3))
        if end_h > start_h:
            target_hour = (start_h + end_h) // 2
        else:
            target_hour = ((start_h + end_h + 24) // 2) % 24

    # Pattern 2: current_time >= [TIME] 'HH:MM' AND current_time <= [TIME] 'HH:MM'
    if target_hour is None:
        m2 = re.search(
            r"current_time\s*>=?\s*(?:TIME\s+)?'(\d{1,2}):(\d{2})'.*?"
            r"current_time\s*<=?\s*(?:TIME\s+)?'(\d{1,2}):(\d{2})'",
            policy_sql, re.IGNORECASE | re.DOTALL,
        )
        if m2:
            start_h, end_h = int(m2.group(1)), int(m2.group(3))
            if end_h > start_h:
                target_hour = (start_h + end_h) // 2
            else:
                target_hour = ((start_h + end_h + 24) // 2) % 24

    # Pattern 3: current_time < [TIME] 'HH:MM' OR current_time >= [TIME] 'HH:MM'
    # Outside business hours — target the complement range
    if target_hour is None:
        m3 = re.search(
            r"current_time\s*<\s*(?:TIME\s+)?'(\d{1,2}):(\d{2})'.*?"
            r"current_time\s*>=?\s*(?:TIME\s+)?'(\d{1,2}):(\d{2})'",
            policy_sql, re.IGNORECASE | re.DOTALL,
        )
        if m3:
            before_h = int(m3.group(1))
            after_h = int(m3.group(3))
            outside_len = (24 - after_h) + before_h
            target_hour = (after_h + outside_len // 2) % 24

    # Pattern 4: EXTRACT(HOUR FROM ...) >= N or BETWEEN N AND M
    if target_hour is None:
        m4 = re.search(
            r"EXTRACT\s*\(\s*HOUR\s+FROM\s+\w+\)\s*(?:>=?|BETWEEN)\s*(\d+)",
            policy_sql, re.IGNORECASE,
        )
        if m4:
            target_hour = int(m4.group(1)) + 1

    # Default to noon
    if target_hour is None:
        target_hour = 12

    now_utc = datetime.datetime.utcnow()
    offset = target_hour - now_utc.hour

    # Normalize offset to [-12, +14] range (valid Etc/GMT offsets)
    # If offset is outside range, wrap around 24 hours
    if offset > 14:
        offset -= 24
    elif offset < -12:
        offset += 24

    # If the policy checks DOW BETWEEN 1 AND 5 (weekdays), ensure the
    # target timezone also makes it a weekday. Shift by +-24h if needed.
    has_dow = bool(re.search(r"EXTRACT\s*\(\s*(?:ISO)?DOW", policy_sql, re.IGNORECASE))
    if has_dow:
        target_dt = now_utc + datetime.timedelta(hours=offset)
        # PostgreSQL DOW: 0=Sunday, 1=Monday, ..., 5=Friday, 6=Saturday
        # ISODOW: 1=Monday, ..., 7=Sunday
        dow = target_dt.weekday()  # Python: 0=Mon, 6=Sun
        # We need DOW 1-5 (Mon-Fri) for PostgreSQL EXTRACT(DOW)
        # Python weekday 0-4 = Mon-Fri (PostgreSQL DOW 1-5)
        if dow >= 5:  # Saturday(5) or Sunday(6)
            # Shift forward to Monday
            shift_days = 7 - dow
            offset += shift_days * 24

    # Clamp to valid range
    offset = max(-12, min(14, offset))
    if offset == 0:
        return "Etc/GMT"
    sign = "+" if offset < 0 else "-"
    return f"Etc/GMT{sign}{abs(offset)}"


def _detect_policy_command(policy_sql: str) -> str:
    """Detect the command type from a CREATE POLICY statement.

    Returns one of: SELECT, INSERT, UPDATE, DELETE, ALL.
    """
    upper = policy_sql.upper()
    if "FOR ALL" in upper:
        return "ALL"
    if "FOR SELECT" in upper:
        return "SELECT"
    if "FOR INSERT" in upper:
        return "INSERT"
    if "FOR UPDATE" in upper:
        return "UPDATE"
    if "FOR DELETE" in upper:
        return "DELETE"
    return "ALL"  # default


def _parse_exists_support_needs(policy_sql, session, seed_rows, target_table):
    """Parse EXISTS subqueries and determine what support rows are needed.

    Returns:
        support_rows: dict of {ref_table: [{col: val, ...}]}
        target_augments: dict of {col: val} to add to target table seed rows
    """
    support_rows = {}
    target_augments = {}

    if "EXISTS" not in policy_sql.upper():
        return support_rows, target_augments

    # Extract balanced-parentheses EXISTS blocks
    exists_blocks = _extract_exists_blocks(policy_sql)

    for block in exists_blocks:
        ref_table, row, augments = _parse_single_exists_block(
            block, session, seed_rows, target_table
        )
        if ref_table and row:
            support_rows.setdefault(ref_table, []).append(row)
        if augments:
            target_augments.update(augments)

    return support_rows, target_augments


def _extract_exists_blocks(sql):
    """Extract the content of each EXISTS (...) block from the SQL."""
    blocks = []
    upper = sql.upper()
    idx = 0
    while True:
        pos = upper.find("EXISTS", idx)
        if pos == -1:
            break
        # Skip NOT EXISTS: support rows must never be inserted for a negated
        # existence check (doing so would wrongly block the operation).
        preceding = upper[:pos].rstrip()
        if preceding.endswith("NOT"):
            idx = pos + 6
            continue
        # Find the opening paren
        paren_start = sql.find("(", pos + 6)
        if paren_start == -1:
            break
        # Balance parentheses
        depth = 1
        i = paren_start + 1
        while i < len(sql) and depth > 0:
            if sql[i] == "(":
                depth += 1
            elif sql[i] == ")":
                depth -= 1
            i += 1
        if depth == 0:
            blocks.append(sql[paren_start + 1 : i - 1].strip())
        idx = i
    return blocks


def _parse_single_exists_block(block, session, seed_rows, target_table):
    """Parse a single EXISTS block and return (ref_table, row_dict, augments).

    Handles:
    - Simple: SELECT 1 FROM <table> [<alias>] WHERE <conditions>
    - Recursive CTE: WITH RECURSIVE <name> AS (SELECT ... FROM <table>
      WHERE <base_conds> UNION ...) SELECT 1 FROM <name> WHERE <final_cond>
    """
    upper = block.upper().strip()
    ref_table = None
    row = {}
    augments = {}

    if upper.startswith("WITH RECURSIVE") or upper.startswith("WITH"):
        # Recursive CTE pattern
        ref_table, row, augments = _parse_recursive_exists(
            block, session, seed_rows, target_table
        )
    else:
        # Simple EXISTS
        ref_table, row, augments = _parse_simple_exists(
            block, session, seed_rows, target_table
        )

    return ref_table, row, augments


def _parse_simple_exists(block, session, seed_rows, target_table):
    """Parse: SELECT 1 FROM <table> [<alias>] WHERE <conditions>"""
    # Extract FROM table
    m = re.search(
        r"SELECT\s+1\s+FROM\s+([\w.]+)(?:\s+(\w+))?\s+WHERE\s+(.*)",
        block, re.IGNORECASE | re.DOTALL,
    )
    if not m:
        return None, {}, {}

    ref_table = m.group(1)
    alias = m.group(2) or ""
    where_clause = m.group(3)

    row, augments = _parse_where_conditions(
        where_clause, alias, ref_table, session, seed_rows, target_table
    )

    return ref_table, row, augments


def _parse_recursive_exists(block, session, seed_rows, target_table):
    """Parse recursive CTE EXISTS block.

    Extract base case table and conditions, plus final WHERE condition.
    To satisfy the recursion, we only need to satisfy the base case
    and have the result match the final WHERE condition.
    """
    # Extract CTE name
    m_cte = re.search(
        r"WITH\s+RECURSIVE\s+(\w+)(?:\([^)]*\))?\s+AS\s*\(",
        block, re.IGNORECASE,
    )
    if not m_cte:
        return None, {}, {}

    cte_name = m_cte.group(1)

    # Find the base case: first SELECT ... FROM <table> WHERE <conds>
    # (before the UNION)
    cte_start = m_cte.end()
    union_pos = block.upper().find("UNION", cte_start)
    if union_pos == -1:
        return None, {}, {}

    base_case = block[cte_start:union_pos].strip()

    # Parse base case FROM and WHERE
    m_base = re.search(
        r"SELECT\s+(?:\w+\.)?([\w, .]+?)\s+FROM\s+([\w.]+)\s+(\w+)\s+WHERE\s+(.*)",
        base_case, re.IGNORECASE | re.DOTALL,
    )
    if not m_base:
        return None, {}, {}

    base_select_cols = m_base.group(1)
    ref_table = m_base.group(2)
    alias = m_base.group(3)
    base_where = m_base.group(4).strip()

    # Parse base case conditions
    row, augments = _parse_where_conditions(
        base_where, alias, ref_table, session, seed_rows, target_table
    )

    # Find the final WHERE: SELECT 1 FROM <cte_name> WHERE <cond>
    # This tells us what column of the CTE result must match the target table
    m_final = re.search(
        r"SELECT\s+1\s+FROM\s+" + cte_name +
        r"(?:\s+\w+)?\s+WHERE\s+(.*?)$",
        block, re.IGNORECASE | re.DOTALL,
    )
    if m_final:
        final_where = m_final.group(1).strip().rstrip(")")
        # Parse: <cte_alias>.<col> = <target_table>.<col>
        m_link = re.search(
            r"(?:\w+\.)?(\w+)\s*=\s*(?:" +
            re.escape(target_table) + r"\.)?(\w+)",
            final_where, re.IGNORECASE,
        )
        if m_link:
            cte_col = m_link.group(1)
            target_col = m_link.group(2)
            # The CTE produces rows from the base case SELECT columns.
            # The base case selects e.g. e.employee_id from ref_table.
            # So cte_col in the final WHERE corresponds to a column in ref_table.
            # We need: ref_table.cte_col = seed_row[target_col]
            seed_val = _get_seed_value(
                seed_rows, target_table, target_col
            )
            if seed_val is not None:
                row[cte_col] = seed_val
            else:
                # Assign a default and augment the seed row
                row[cte_col] = 1
                augments[target_col] = 1

    return ref_table, row, augments


def _parse_where_conditions(where_clause, alias, ref_table, session,
                            seed_rows, target_table):
    """Parse WHERE conditions and build a row dict + target augments."""
    row = {}
    augments = {}

    # Strip trailing parentheses
    where_clause = where_clause.strip().rstrip(")")

    # Split on AND (simple split, won't handle nested AND in subqueries)
    parts = re.split(r"\bAND\b", where_clause, flags=re.IGNORECASE)

    for part in parts:
        part = part.strip()
        if not part:
            continue

        # Remove alias prefix for column extraction
        col_prefix = (alias + ".") if alias else ""

        # Pattern: <col> = current_setting('app.<attr>', true)::int
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s*=\s*"
            r"current_setting\s*\(\s*'app\.(\w+)'",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            attr = m.group(2)
            session_key = "app." + attr
            val = session.get(session_key)
            if val is not None:
                # Check for ::int cast
                if "::int" in part.lower():
                    try:
                        val = int(val)
                    except (ValueError, TypeError):
                        pass
                row[col] = val
            continue

        # Pattern: <col> = '<literal>'
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s*=\s*'([^']*)'",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            val = m.group(2)
            row[col] = val
            continue

        # Pattern: <col> = true/false
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s*=\s*(true|false)",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            val = m.group(2).lower() == "true"
            row[col] = val
            continue

        # Pattern: <col> = <target_table>.<col> (cross-table reference)
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s*=\s*"
            + re.escape(target_table) + r"\.(\w+)",
            part, re.IGNORECASE,
        )
        if m:
            ref_col = m.group(1)
            target_col = m.group(2)
            seed_val = _get_seed_value(seed_rows, target_table, target_col)
            if seed_val is not None:
                row[ref_col] = seed_val
            else:
                # Assign a default and augment the seed row
                row[ref_col] = 1
                augments[target_col] = 1
            continue

        # Pattern: <col> IS NOT NULL
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s+IS\s+NOT\s+NULL",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            if col not in row:
                row[col] = 1  # default non-null
            continue

        # Pattern: <col> IN ('val1', 'val2', ...)
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s+IN\s*\(\s*'([^']*)'",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            val = m.group(2)  # first value
            row[col] = val
            continue

        # Pattern: <col> = <number>
        m = re.search(
            r"(?:" + re.escape(col_prefix) + r")?(\w+)\s*=\s*(\d+)",
            part, re.IGNORECASE,
        )
        if m:
            col = m.group(1)
            val = int(m.group(2))
            row[col] = val
            continue

    return row, augments


def _get_seed_value(seed_rows, table, col):
    """Get a column value from the seed rows for a given table."""
    rows = seed_rows.get(table, [])
    if rows and isinstance(rows, list):
        return rows[0].get(col)
    return None



def _fix_session_defaults(session, policy_sql):
    """Fix 'default_value' session vars by inferring from policy SQL."""
    fixed = dict(session)
    for key, val in fixed.items():
        if val != "default_value":
            continue
        attr = key.replace("app.", "")
        # Check if policy casts this to boolean
        if re.search(
            r"current_setting\s*\(\s*'" + re.escape(key) + r"'.*?\)\s*::\s*boolean\s*=\s*true",
            policy_sql, re.IGNORECASE,
        ):
            fixed[key] = "true"
        elif re.search(
            r"current_setting\s*\(\s*'" + re.escape(key) + r"'.*?\)\s*::\s*boolean\s*=\s*false",
            policy_sql, re.IGNORECASE,
        ):
            fixed[key] = "false"
        elif re.search(
            r"current_setting\s*\(\s*'" + re.escape(key) + r"'.*?\)\s*::\s*int",
            policy_sql, re.IGNORECASE,
        ):
            fixed[key] = "1"
        else:
            fixed[key] = "true"  # best guess for IS NOT NULL checks
    return fixed


def _fix_temporal_seed_values(seed_rows, table, policy_sql):
    """Fix seed row column values for temporal conditions.

    Detects patterns like:
    - column >= current_date - INTERVAL 'N days'
    - column <= CURRENT_TIMESTAMP - INTERVAL 'N years'
    - column < current_date - INTERVAL 'N days'

    Sets the seed row column to a date/timestamp that satisfies the condition.
    """
    import datetime

    today = datetime.date.today()
    now = datetime.datetime.now()

    target_seeds = seed_rows.get(table, [])
    if not target_seeds:
        return

    # Find temporal conditions
    # Pattern: <col> >= current_date - INTERVAL '<N> <unit>'
    for m in re.finditer(
        r"(\w+)\s*(>=|>)\s*(?:current_date|CURRENT_DATE)\s*-\s*"
        r"INTERVAL\s*'(\d+)\s+(\w+)'",
        policy_sql, re.IGNORECASE,
    ):
        col, op, n, unit = m.group(1), m.group(2), int(m.group(3)), m.group(4).lower()
        if unit.startswith("day"):
            target_date = today - datetime.timedelta(days=n // 2)
        elif unit.startswith("month"):
            target_date = today - datetime.timedelta(days=n * 15)
        elif unit.startswith("year"):
            target_date = today - datetime.timedelta(days=n * 180)
        else:
            continue
        for row in target_seeds:
            if col not in row or row[col] is None:
                row[col] = str(target_date)

    # Pattern: <col> <= CURRENT_TIMESTAMP - INTERVAL '<N> <unit>'
    # (needs OLD dates, e.g., archived records)
    for m in re.finditer(
        r"(\w+)\s*(<=|<)\s*(?:CURRENT_TIMESTAMP|current_timestamp|NOW\(\))\s*-\s*"
        r"INTERVAL\s*'(\d+)\s+(\w+)'",
        policy_sql, re.IGNORECASE,
    ):
        col, op, n, unit = m.group(1), m.group(2), int(m.group(3)), m.group(4).lower()
        if unit.startswith("day"):
            target_ts = now - datetime.timedelta(days=n + 30)
        elif unit.startswith("month"):
            target_ts = now - datetime.timedelta(days=n * 31 + 30)
        elif unit.startswith("year"):
            target_ts = now - datetime.timedelta(days=n * 366 + 30)
        else:
            continue
        for row in target_seeds:
            if col not in row or row[col] is None:
                row[col] = str(target_ts.date())

    # Pattern: <col> >= current_date (without interval)
    for m in re.finditer(
        r"(\w+)\s*>=\s*(?:current_date|CURRENT_DATE)(?!\s*-)",
        policy_sql, re.IGNORECASE,
    ):
        col = m.group(1)
        for row in target_seeds:
            if col not in row or row[col] is None:
                row[col] = str(today + datetime.timedelta(days=365))


def _get_fk_constraints(conn, table: str) -> list:
    """Get FK constraints for a table. Returns list of (col, ref_table, ref_col)."""
    schema, tbl = table.split(".", 1)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT
                kcu.column_name,
                ccu.table_schema || '.' || ccu.table_name AS ref_table,
                ccu.column_name AS ref_column
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.constraint_name
                AND tc.table_schema = ccu.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND tc.table_schema = %s
                AND tc.table_name = %s
        """, (schema, tbl))
        return [(r[0], r[1], r[2]) for r in cur.fetchall()]


def _ensure_fk_parents(cur, table, seed_rows, fk_constraints,
                       not_null_cols, all_cols_cache):
    """Ensure parent rows exist for FK values in seed rows.

    For each FK constraint, check if the referenced row exists.
    If not, insert a minimal parent row.

    Returns list of (ref_table, pk_col, pk_val) for cleanup.
    """
    inserted_parents = []
    if not fk_constraints:
        return inserted_parents

    target_seeds = seed_rows.get(table, [])

    for fk_col, ref_table, ref_col in fk_constraints:
        # Collect FK values from seed rows
        fk_vals = set()
        for row in target_seeds:
            val = row.get(fk_col)
            if val is not None:
                fk_vals.add(val)

        for fk_val in fk_vals:
            try:
                # Check if parent row exists
                cur.execute(
                    f"SELECT 1 FROM {ref_table} WHERE {ref_col} = %s",
                    (fk_val,),
                )
                if cur.fetchone():
                    continue  # Already exists

                # Insert minimal parent row
                parent_row = {ref_col: fk_val}
                ref_nn = not_null_cols.get(ref_table, {})
                ref_all = (all_cols_cache or {}).get(ref_table, {})
                if ref_all:
                    parent_row = validate_seed_row(parent_row, ref_all)
                parent_row = fill_required_columns(parent_row, ref_nn)
                insert_seed_row(cur, ref_table, parent_row)
                inserted_parents.append((ref_table, ref_col, fk_val))
            except Exception as e:
                logger.debug("FK parent insert failed for %s.%s=%s: %s",
                             ref_table, ref_col, fk_val, e)

    return inserted_parents



def _augment_insert_sql(
    sql: str,
    table: str,
    nn_cols: Dict[str, str],
    all_cols: Dict[str, str],
) -> str:
    """Add missing NOT NULL columns to INSERT SQL to avoid constraint errors.

    Parses the INSERT INTO ... (cols) VALUES (vals) statement, adds any
    NOT NULL columns that are missing, with type-appropriate defaults.
    """
    if not nn_cols:
        return sql

    # Extract existing columns from INSERT
    m = re.match(
        r"INSERT\s+INTO\s+\S+\s*\(([^)]+)\)\s*VALUES\s*\((.+)\)\s*;?",
        sql, re.IGNORECASE,
    )
    if not m:
        return sql

    existing_cols_str = m.group(1)
    existing_vals_str = m.group(2)

    existing_cols = [c.strip().strip('"') for c in existing_cols_str.split(",")]
    # Simple value splitting (handles quoted strings with commas inside)
    vals_parts = []
    depth = 0
    current = ""
    in_quote = False
    for ch in existing_vals_str:
        if ch == "'" and not in_quote:
            in_quote = True
            current += ch
        elif ch == "'" and in_quote:
            in_quote = False
            current += ch
        elif ch == "," and not in_quote and depth == 0:
            vals_parts.append(current.strip())
            current = ""
        elif ch == "(":
            depth += 1
            current += ch
        elif ch == ")":
            depth -= 1
            current += ch
        else:
            current += ch
    if current.strip():
        vals_parts.append(current.strip())

    existing_set = set(existing_cols)
    added_cols = []
    added_vals = []
    for col, dtype in nn_cols.items():
        if col not in existing_set:
            default = _TYPE_DEFAULTS.get(dtype, "")
            if isinstance(default, str):
                added_vals.append(f"'{default}'")
            elif isinstance(default, bool):
                added_vals.append("true" if default else "false")
            else:
                added_vals.append(str(default))
            added_cols.append(f'"{col}"')

    if not added_cols:
        return sql

    all_cols_str = existing_cols_str + ", " + ", ".join(added_cols)
    all_vals_str = existing_vals_str + ", " + ", ".join(added_vals)
    return f"INSERT INTO {table} ({all_cols_str}) VALUES ({all_vals_str});"


BASE_SELECT_POLICY = "rls_base_select_policy"


def run_single_test(
    admin_conn,
    db_args,
    table: str,
    test_case: Dict,
    policy_sql: str,
    not_null_cols: Dict[str, str],
    all_cols_cache: Optional[Dict[str, Dict[str, str]]] = None,
    fk_constraints: Optional[list] = None,
    check_cache: Optional[Dict[str, Dict[str, Any]]] = None,
) -> TestResult:
    """Run a single test case and return the result.

    Strategy:
    1. Setup phase (superuser, autocommit): truncate, insert seeds,
       create policy, enable RLS.
    2. Action phase (fresh test_role connection): SET session vars,
       execute action, read results.
    3. Cleanup phase (superuser, autocommit): drop policy, disable RLS.

    Uses a FRESH connection for the action phase to ensure no GUC leakage.
    """
    case_id = test_case["case_id"]
    purpose = test_case["purpose"]
    category = test_case.get("category", "")
    session = test_case.get("session", {})
    seed_rows = test_case.get("seed_rows", {})
    action = test_case["action"]
    expected = test_case["expected"]

    actual = {}
    error_msg = None
    _support_originals = []  # populated in setup, used in cleanup
    _seed_originals = []  # explicit non-target fixtures restored in cleanup
    _fk_parents = []  # FK parent rows inserted for cleanup
    _rls_disabled = []  # referenced tables whose RLS was disabled for the test
    _rls_snapshot = None  # policies and RLS flags before the test

    try:
        # --- SETUP PHASE (superuser, autocommit) ---
        admin_conn.autocommit = True
        with admin_conn.cursor() as cur:
            _rls_snapshot = snapshot_rls_state(cur)
            # Truncate target table
            cur.execute(f"TRUNCATE {table} CASCADE")

            # Disable FK checking for seed insertion
            cur.execute("SET session_replication_role = 'replica'")

            # Fix temporal conditions in seed rows
            _fix_temporal_seed_values(seed_rows, table, policy_sql)

            # Insert seed rows
            for tbl, rows in seed_rows.items():
                tbl_nn = not_null_cols.get(tbl, {})
                tbl_all = (all_cols_cache or {}).get(tbl, {})
                for row in rows:
                    # 1. Validate: remove non-existent columns, fix types
                    validated = validate_seed_row(row, tbl_all) if tbl_all else row
                    # 2. Fill missing NOT NULL columns
                    filled = fill_required_columns(
                        validated, tbl_nn, (check_cache or {}).get(tbl))
                    if tbl == table:
                        insert_seed_row(cur, tbl, filled)
                        continue

                    # Referenced fixtures are shared across cases and runs.
                    # Upsert them by primary key and remember the prior row so
                    # rerunning a suite is deterministic instead of raising a
                    # duplicate-key error on the second case/run.
                    pk = _get_pk_col_from_table(tbl)
                    pk_val = filled.get(pk)
                    if pk_val is None:
                        insert_seed_row(cur, tbl, filled)
                        continue
                    cur.execute(f"SELECT * FROM {tbl} WHERE {pk} = %s", (pk_val,))
                    existing = cur.fetchone()
                    if existing:
                        names = [desc[0] for desc in cur.description]
                        _seed_originals.append((tbl, pk, pk_val, dict(zip(names, existing))))
                        assignments = [col for col in filled if col != pk]
                        if assignments:
                            cur.execute(
                                f"UPDATE {tbl} SET "
                                + ", ".join(f"{col} = %s" for col in assignments)
                                + f" WHERE {pk} = %s",
                                [filled[col] for col in assignments] + [pk_val],
                            )
                    else:
                        _seed_originals.append((tbl, pk, pk_val, None))
                        insert_seed_row(cur, tbl, filled)

            # --- INSERT FK PARENT ROWS ---
            # Ensure parent rows exist for FK references in seed data
            fk_constraints = fk_constraints or []
            _fk_parents = _ensure_fk_parents(
                cur, table, seed_rows, fk_constraints,
                not_null_cols, all_cols_cache,
            )

            # --- INSERT EXISTS SUPPORT ROWS ---
            # Parse policy for EXISTS subqueries and insert support rows
            # in referenced tables to satisfy cross-table conditions.
            if test_case.get("disable_auto_support"):
                support_rows, target_augments = {}, {}
            else:
                support_rows, target_augments = _parse_exists_support_needs(
                    policy_sql, session, seed_rows, table,
                )
            # If augments are needed, UPDATE seed rows in target table
            if target_augments:
                pk_col = _get_pk_col_from_table(table)
                target_seeds = seed_rows.get(table, [])
                for seed_row in target_seeds:
                    pk_val = seed_row.get(pk_col)
                    if pk_val is not None:
                        set_parts = []
                        set_vals = []
                        for col, val in target_augments.items():
                            if col not in seed_row:
                                set_parts.append(f"{col} = %s")
                                set_vals.append(val)
                        if set_parts:
                            set_vals.append(pk_val)
                            cur.execute(
                                f"UPDATE {table} SET {', '.join(set_parts)} "
                                f"WHERE {pk_col} = %s",
                                set_vals,
                            )

            # Insert support rows for EXISTS subquery tables
            # Track originals for cleanup/restore
            _support_originals = []  # [(ref_tbl, pk_col, pk_val, orig_row_or_None)]
            for ref_tbl, ref_rows in support_rows.items():
                ref_nn = not_null_cols.get(ref_tbl, {})
                ref_all = (all_cols_cache or {}).get(ref_tbl, {})
                if not ref_all:
                    try:
                        ref_all = get_all_columns(admin_conn, ref_tbl)
                        if all_cols_cache is not None:
                            all_cols_cache[ref_tbl] = ref_all
                    except Exception:
                        ref_all = {}
                if not ref_nn:
                    try:
                        ref_nn = get_not_null_columns(admin_conn, ref_tbl)
                        not_null_cols[ref_tbl] = ref_nn
                    except Exception:
                        ref_nn = {}
                for ref_row in ref_rows:
                    pk = _get_pk_col_from_table(ref_tbl)
                    if pk not in ref_row:
                        ref_row[pk] = 99999
                    if ref_all:
                        ref_row = validate_seed_row(ref_row, ref_all)
                    ref_row = fill_required_columns(
                        ref_row, ref_nn, (check_cache or {}).get(ref_tbl))
                    pk_val = ref_row.get(pk)
                    try:
                        # Check if row already exists
                        cur.execute(
                            f"SELECT * FROM {ref_tbl} WHERE {pk} = %s",
                            (pk_val,),
                        )
                        existing = cur.fetchone()
                        if existing:
                            # Save original for restore
                            col_names = [d[0] for d in cur.description]
                            orig = dict(zip(col_names, existing))
                            _support_originals.append(
                                (ref_tbl, pk, pk_val, orig)
                            )
                            # UPDATE existing row
                            set_parts = []
                            set_vals = []
                            for col, val in ref_row.items():
                                if col != pk:
                                    set_parts.append(f"{col} = %s")
                                    set_vals.append(val)
                            if set_parts:
                                set_vals.append(pk_val)
                                cur.execute(
                                    f"UPDATE {ref_tbl} SET "
                                    + ", ".join(set_parts)
                                    + f" WHERE {pk} = %s",
                                    set_vals,
                                )
                        else:
                            # INSERT new row
                            _support_originals.append(
                                (ref_tbl, pk, pk_val, None)
                            )
                            insert_seed_row(cur, ref_tbl, ref_row)
                    except Exception as e:
                        logger.debug(
                            "Support row upsert failed for %s: %s",
                            ref_tbl, e,
                        )

            # Re-enable FK checking
            cur.execute("SET session_replication_role = 'origin'")

            # Disable RLS on referenced (non-target) tables so EXISTS/subquery
            # checks run by the test role can read their rows. The target
            # table's RLS stays enabled (that's what we're testing).
            _ref_tables = (set(seed_rows.keys()) | set(support_rows.keys())) - {table}
            for ref_t in _ref_tables:
                try:
                    schema_r, tbl_r = ref_t.split(".", 1)
                    cur.execute(
                        "SELECT relrowsecurity FROM pg_class c "
                        "JOIN pg_namespace n ON n.oid=c.relnamespace "
                        "WHERE n.nspname=%s AND c.relname=%s",
                        (schema_r, tbl_r),
                    )
                    row_rls = cur.fetchone()
                    if row_rls and row_rls[0]:
                        cur.execute(f"ALTER TABLE {ref_t} DISABLE ROW LEVEL SECURITY")
                        _rls_disabled.append(ref_t)
                except Exception as e:
                    logger.debug("RLS disable failed for %s: %s", ref_t, e)

            # Drop existing policies
            drop_all_policies(cur, table)

            # Enable RLS
            enable_rls(cur, table)

            # Create the policy
            create_policy(cur, policy_sql)

            # For non-SELECT policies, add a permissive SELECT policy
            # so rows are visible. PostgreSQL RLS requires rows to pass
            # a SELECT-type policy before DELETE/UPDATE/INSERT can
            # operate on them; without one, default-deny hides all rows.
            policy_cmd = _detect_policy_command(policy_sql)
            needs_base_select = policy_cmd in ("DELETE", "UPDATE", "INSERT")
            if needs_base_select:
                cur.execute(
                    f"CREATE POLICY {BASE_SELECT_POLICY} ON {table} "
                    f"FOR SELECT USING (true)"
                )

            # Disable triggers that might block test role
            # (e.g., audit triggers that INSERT into tables test role can't access)
            cur.execute(f"ALTER TABLE {table} DISABLE TRIGGER ALL")

            # Grant access to test role
            schema_name = table.split(".")[0]
            cur.execute(
                f"GRANT USAGE ON SCHEMA {schema_name} TO {TEST_ROLE}"
            )
            cur.execute(
                f"GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO {TEST_ROLE}"
            )
            # Grant INSERT on audit tables as fallback
            try:
                cur.execute(
                    f"GRANT INSERT ON operations.entity_audit_events TO {TEST_ROLE}"
                )
            except Exception:
                pass

        # --- ACTION PHASE (fresh test_role connection) ---
        # Fresh connection ensures no GUC leakage from prior tests.
        test_conn = psycopg2.connect(
            host=db_args.db_host,
            port=db_args.db_port,
            user=TEST_ROLE,
            password=TEST_ROLE_PASSWORD,
            dbname=db_args.db_name,
            options=STATEMENT_TIMEOUT_OPTION,
        )
        test_conn.autocommit = False

        try:
            with test_conn.cursor() as cur:
                # If mock_time is present, app_now() becomes deterministic and we
                # want the timezone to match the mock_time literal (assumed UTC).
                # Otherwise fall back to the timezone-shift trick to land
                # current_time in the policy's business-hour range.
                mock_time = test_case.get("mock_time")
                if mock_time:
                    cur.execute("SET LOCAL timezone = 'UTC'")
                    cur.execute("SELECT set_config('app.now', %s, true)", (str(mock_time),))
                else:
                    cur.execute(
                        "SET LOCAL timezone = %s",
                        (_business_hours_timezone(policy_sql),),
                    )

                # Fix session default_value vars
                session = _fix_session_defaults(session, policy_sql)

                # Inject the session context (transaction-local) right before the action
                for key, val in session.items():
                    cur.execute("SELECT set_config(%s, %s, true)", (key, str(val)))

                # Execute action
                action_type = action["type"]
                action_sql = action["sql"]

                # Augment INSERT SQL with missing NOT NULL columns
                if action_type == "INSERT" and all_cols_cache:
                    action_sql = _augment_insert_sql(
                        action_sql, table,
                        not_null_cols.get(table, {}),
                        (all_cols_cache or {}).get(table, {}),
                    )

                try:
                    cur.execute(action_sql)

                    if action_type == "SELECT":
                        rows = cur.fetchall()
                        col_names = [d[0] for d in cur.description]
                        pk_col = _get_pk_col_from_table(table)
                        pk_idx = None
                        for i, c in enumerate(col_names):
                            if c == pk_col:
                                pk_idx = i
                                break

                        visible_pks = []
                        if pk_idx is not None:
                            visible_pks = [r[pk_idx] for r in rows]

                        actual = {
                            "outcome": "success",
                            "row_count": len(rows),
                            "visible_primary_keys": sorted(visible_pks),
                        }
                    else:
                        actual = {
                            "outcome": "success",
                            "row_count": cur.rowcount,
                        }

                except psycopg2.errors.InsufficientPrivilege:
                    actual = {"outcome": "rls_check_error"}
                except psycopg2.errors.CheckViolation:
                    actual = {"outcome": "rls_check_error"}
                except psycopg2.Error as e:
                    err_str = str(e).lower()
                    pgcode = e.pgcode or ""
                    if "new row violates row-level security" in err_str:
                        actual = {"outcome": "rls_check_error"}
                    elif "permission denied" in err_str:
                        actual = {"outcome": "rls_check_error"}
                    elif pgcode.startswith("42"):
                        # 42xxx = syntax/schema errors
                        actual = {
                            "outcome": "schema_error",
                            "detail": str(e)[:200],
                        }
                    elif pgcode in ("23502", "23503", "23505"):
                        # NOT NULL / FK / unique constraint violations
                        # are seed data issues, not RLS behavior
                        actual = {
                            "outcome": "constraint_error",
                            "detail": str(e)[:200],
                        }
                    elif pgcode == "23514":
                        # CHECK constraint — could be RLS WITH CHECK
                        actual = {"outcome": "rls_check_error",
                                  "detail": str(e)[:200]}
                    else:
                        actual = {"outcome": "rls_check_error",
                                  "detail": f"pgcode={pgcode}: {str(e)[:180]}"}
        finally:
            test_conn.rollback()
            test_conn.close()

        # --- CLEANUP PHASE (superuser, autocommit) ---
        admin_conn.autocommit = True
        with admin_conn.cursor() as cur:
            drop_all_policies(cur, table)
            disable_rls(cur, table)
            restore_rls_state(cur, _rls_snapshot)
            # Re-enable RLS on referenced tables we disabled for the test
            for ref_t in _rls_disabled:
                try:
                    cur.execute(f"ALTER TABLE {ref_t} ENABLE ROW LEVEL SECURITY")
                except Exception:
                    pass
            # Re-enable triggers
            try:
                cur.execute(f"ALTER TABLE {table} ENABLE TRIGGER ALL")
            except Exception:
                pass
            # Clean up FK parent rows that we inserted
            if _fk_parents:
                cur.execute("SET session_replication_role = 'replica'")
                for ref_tbl, ref_col, ref_val in _fk_parents:
                    try:
                        cur.execute(
                            f"DELETE FROM {ref_tbl} WHERE {ref_col} = %s",
                            (ref_val,),
                        )
                    except Exception:
                        pass
                cur.execute("SET session_replication_role = 'origin'")

            # Restore original rows modified by EXISTS support
            if _support_originals:
                cur.execute("SET session_replication_role = 'replica'")
                for ref_tbl, pk_col, pk_val, orig in _support_originals:
                    try:
                        if orig is None:
                            # Row was newly inserted — delete it
                            cur.execute(
                                f"DELETE FROM {ref_tbl} WHERE {pk_col} = %s",
                                (pk_val,),
                            )
                        else:
                            # Row was updated — restore original values
                            set_parts = []
                            set_vals = []
                            for col, val in orig.items():
                                if col != pk_col:
                                    set_parts.append(f"{col} = %s")
                                    set_vals.append(val)
                            if set_parts:
                                set_vals.append(pk_val)
                                cur.execute(
                                    f"UPDATE {ref_tbl} SET "
                                    + ", ".join(set_parts)
                                    + f" WHERE {pk_col} = %s",
                                    set_vals,
                                )
                    except Exception:
                        pass
                cur.execute("SET session_replication_role = 'origin'")

            # Restore/delete explicit non-target fixtures after any EXISTS
            # support rows have been restored to their seed-time state.
            if _seed_originals:
                cur.execute("SET session_replication_role = 'replica'")
                for ref_tbl, pk_col, pk_val, orig in reversed(_seed_originals):
                    try:
                        if orig is None:
                            cur.execute(
                                f"DELETE FROM {ref_tbl} WHERE {pk_col} = %s",
                                (pk_val,),
                            )
                        else:
                            cols = [col for col in orig if col != pk_col]
                            if cols:
                                cur.execute(
                                    f"UPDATE {ref_tbl} SET "
                                    + ", ".join(f"{col} = %s" for col in cols)
                                    + f" WHERE {pk_col} = %s",
                                    [orig[col] for col in cols] + [pk_val],
                                )
                    except Exception:
                        pass
                cur.execute("SET session_replication_role = 'origin'")

    except Exception as e:
        error_msg = traceback.format_exc()[-500:]
        actual = {"outcome": "harness_error", "detail": str(e)[:200]}
        try:
            admin_conn.rollback()
            admin_conn.autocommit = True
            with admin_conn.cursor() as cur:
                drop_all_policies(cur, table)
                disable_rls(cur, table)
                restore_rls_state(cur, _rls_snapshot)
                # Re-enable triggers
                try:
                    cur.execute(f"ALTER TABLE {table} ENABLE TRIGGER ALL")
                except Exception:
                    pass
                # Restore support originals on error path too
                if _support_originals:
                    cur.execute("SET session_replication_role = 'replica'")
                    for ref_tbl, pk_col, pk_val, orig in _support_originals:
                        try:
                            if orig is None:
                                cur.execute(
                                    f"DELETE FROM {ref_tbl} WHERE {pk_col} = %s",
                                    (pk_val,),
                                )
                            else:
                                set_parts = []
                                set_vals = []
                                for col, val in orig.items():
                                    if col != pk_col:
                                        set_parts.append(f"{col} = %s")
                                        set_vals.append(val)
                                if set_parts:
                                    set_vals.append(pk_val)
                                    cur.execute(
                                        f"UPDATE {ref_tbl} SET "
                                        + ", ".join(set_parts)
                                        + f" WHERE {pk_col} = %s",
                                        set_vals,
                                    )
                        except Exception:
                            pass
                    cur.execute("SET session_replication_role = 'origin'")
                if _seed_originals:
                    cur.execute("SET session_replication_role = 'replica'")
                    for ref_tbl, pk_col, pk_val, orig in reversed(_seed_originals):
                        try:
                            if orig is None:
                                cur.execute(
                                    f"DELETE FROM {ref_tbl} WHERE {pk_col} = %s",
                                    (pk_val,),
                                )
                            else:
                                cols = [col for col in orig if col != pk_col]
                                if cols:
                                    cur.execute(
                                        f"UPDATE {ref_tbl} SET "
                                        + ", ".join(f"{col} = %s" for col in cols)
                                        + f" WHERE {pk_col} = %s",
                                        [orig[col] for col in cols] + [pk_val],
                                    )
                        except Exception:
                            pass
                    cur.execute("SET session_replication_role = 'origin'")
        except Exception:
            pass

    # Compare expected vs actual
    passed = _compare_result(expected, actual)

    return TestResult(
        case_id=case_id,
        purpose=purpose,
        passed=passed,
        expected=expected,
        actual=actual,
        error=error_msg,
        category=category,
    )


def _get_pk_col_from_table(table: str) -> str:
    """Get the PK column name for a table from the hardcoded map."""
    from generate_test_cases import TABLE_PK_MAP
    return TABLE_PK_MAP.get(table, "id")


def _compare_result(expected: Dict, actual: Dict) -> bool:
    """Compare expected outcome against actual result."""
    if expected.get("outcome") != actual.get("outcome"):
        return False

    # For SELECT: check visible/hidden PKs
    if "visible_primary_keys" in expected:
        exp_vis = set(expected["visible_primary_keys"])
        act_vis = set(actual.get("visible_primary_keys", []))
        if exp_vis != act_vis:
            return False
        # Check hidden PKs: anything in expected hidden should NOT be in actual visible
        exp_hid = set(expected.get("hidden_primary_keys", []))
        if exp_hid & act_vis:
            return False

    # For INSERT/UPDATE/DELETE: check row_count
    if "row_count" in expected:
        if expected["row_count"] != actual.get("row_count"):
            return False

    return True


# ---------------------------------------------------------------------------
# Metrics computation
# ---------------------------------------------------------------------------

def compute_metrics(
    results: List[Dict],
) -> Dict[str, float]:
    """Compute execution-based metrics from test results.

    Metrics (Eqs. (4)-(10) of the paper):
    - behavior_accuracy: passed test cases / all test cases, including the tests of
      items without a predicted policy
    - opr (Over-Privilege Rate): fraction of negative test cases that are not denied
    - upr (Under-Privilege Rate): fraction of positive test cases that wrongly fail
    - security_pass_0fp: fraction of items where ALL negative and missing-session
      cases pass
    - default_deny_pass: fraction of missing_session cases that correctly deny
    All metrics are computed over all items. Tests of items without a predicted
    policy, or whose policy fails to install, count as failed.
    """
    total = 0
    passed = 0
    pos_total = 0
    pos_pass = 0
    neg_total = 0
    neg_pass = 0
    missing_total = 0
    missing_pass = 0

    # Per-item tracking for security_pass
    item_neg_results = {}  # item_id → list of bool

    for item_result in results:
        item_id = item_result["id"]
        # Tests of items without a predicted policy count as failed.
        skipped = [{"purpose": p, "passed": False}
                   for p in item_result.get("skipped_test_purposes", [])]
        for tc in item_result.get("test_results", []) + skipped:
            total += 1
            if tc["passed"]:
                passed += 1

            purpose = tc["purpose"]
            if purpose == "positive":
                pos_total += 1
                if tc["passed"]:
                    pos_pass += 1
            elif purpose in ("negative", "role_mismatch", "with_check_negative"):
                neg_total += 1
                if tc["passed"]:
                    neg_pass += 1
                item_neg_results.setdefault(item_id, []).append(tc["passed"])
            elif purpose == "missing_session":
                missing_total += 1
                if tc["passed"]:
                    missing_pass += 1
                # Also count as a security/negative test
                item_neg_results.setdefault(item_id, []).append(tc["passed"])

    behavior_accuracy = passed / total if total > 0 else 0.0
    opr = 1.0 - (neg_pass / neg_total) if neg_total > 0 else 0.0
    upr = 1.0 - (pos_pass / pos_total) if pos_total > 0 else 0.0

    # Security Pass@0FP: items where ALL negative/missing tests pass
    items_with_neg = len(item_neg_results)
    items_all_neg_pass = sum(
        1 for results_list in item_neg_results.values()
        if all(results_list)
    )
    security_pass = items_all_neg_pass / items_with_neg if items_with_neg > 0 else 0.0

    default_deny = missing_pass / missing_total if missing_total > 0 else 0.0

    # PCS: Policy Creation Success
    # An item has PCS=1 if at least one test case does NOT have 
    # outcome="harness_error" (meaning the policy was created successfully)
    pcs_total = 0
    pcs_success = 0
    for item_result in results:
        test_results = item_result.get("test_results", [])
        if not test_results:
            # No test cases → skip (possibly no prediction)
            if item_result.get("skip_reason"):
                pcs_total += 1  # count as PCS failure
            continue
        pcs_total += 1
        # Check if all tests have harness_error → policy creation failed
        all_harness = all(
            (tr.get("actual", {}).get("outcome") == "harness_error"
             if isinstance(tr.get("actual"), dict) else False)
            for tr in test_results
        )
        if not all_harness:
            pcs_success += 1
    pcs = pcs_success / pcs_total if pcs_total > 0 else 0.0

    # Strict per-policy intent accuracy: a policy is correct only when every
    # executable positive, negative, and default-deny case for it passes.
    ia_total = len(results)
    ia_pass = sum(
        1
        for item_result in results
        if item_result.get("test_results")
        and all(tc.get("passed") for tc in item_result["test_results"])
    )
    intent_accuracy = ia_pass / ia_total if ia_total > 0 else 0.0

    return {
        "intent_accuracy": round(intent_accuracy, 4),
        "ia_detail": f"{ia_pass}/{ia_total}",
        "policy_creation_success": round(pcs, 4),
        "behavior_accuracy": round(behavior_accuracy, 4),
        "over_privilege_rate": round(opr, 4),
        "under_privilege_rate": round(upr, 4),
        "security_pass_0fp": round(security_pass, 4),
        "default_deny_pass_rate": round(default_deny, 4),
        "total_test_cases": total,
        "total_passed": passed,
        "positive_pass": f"{pos_pass}/{pos_total}",
        "negative_pass": f"{neg_pass}/{neg_total}",
        "missing_session_pass": f"{missing_pass}/{missing_total}",
        "pcs_detail": f"{pcs_success}/{pcs_total}",
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run_evaluation(args: argparse.Namespace) -> None:
    """Main evaluation loop."""
    # Load test cases
    logger.info("Loading test cases from %s", args.test_cases_path)
    with open(args.test_cases_path) as f:
        test_cases = json.load(f)
    logger.info("Loaded %d items", len(test_cases))

    # Load benchmark (for gold SQL)
    logger.info("Loading benchmark from %s", args.benchmark_path)
    with open(args.benchmark_path) as f:
        benchmark = json.load(f)
    gold_map = {item["id"]: item["sql"] for item in benchmark}
    logger.info("Loaded %d gold policies", len(gold_map))

    # Load predictions if mode=pred
    pred_map = {}
    if args.mode == "pred":
        logger.info("Loading predictions from %s", args.predictions_path)
        with open(args.predictions_path) as f:
            predictions = json.load(f)
        pred_map = {
            p["id"]: p.get("predicted_sql", "")
            for p in predictions
        }
        logger.info("Loaded %d predictions", len(pred_map))

    # Connect to DB
    conn = get_connection(args)
    conn.autocommit = True
    ensure_test_role(conn)

    # Cache NOT NULL column info and all-column info per table
    nn_cache = {}
    all_cols_cache = {}
    fk_cache = {}
    check_cache = {}

    results = []
    total_cases = 0
    total_passed = 0
    total_errors = 0

    for i, tc_item in enumerate(test_cases):
        item_id = tc_item["id"]
        table = tc_item.get("target_table")
        operation = tc_item.get("operation")
        test_case_list = tc_item.get("test_cases", [])

        if not table or not test_case_list:
            results.append({
                "id": item_id,
                "target_table": table,
                "operation": operation,
                "test_results": [],
                "skipped_test_purposes": [tc.get("purpose") for tc in test_case_list],
                "skip_reason": "no target table or test cases",
            })
            continue

        # Get policy SQL
        if args.mode == "gold":
            policy_sql = gold_map.get(item_id, "")
        else:
            policy_sql = pred_map.get(item_id, "")

        if not policy_sql:
            results.append({
                "id": item_id,
                "target_table": table,
                "operation": operation,
                "test_results": [],
                "skipped_test_purposes": [tc.get("purpose") for tc in test_case_list],
                "skip_reason": "no policy SQL",
            })
            continue

        # Cache NOT NULL columns and all columns (autocommit — no commit needed)
        for tbl_to_cache in [table]:
            if tbl_to_cache not in nn_cache:
                try:
                    nn_cache[tbl_to_cache] = get_not_null_columns(conn, tbl_to_cache)
                except Exception:
                    nn_cache[tbl_to_cache] = {}
            if tbl_to_cache not in all_cols_cache:
                try:
                    all_cols_cache[tbl_to_cache] = get_all_columns(conn, tbl_to_cache)
                except Exception:
                    all_cols_cache[tbl_to_cache] = {}
            if tbl_to_cache not in check_cache:
                try:
                    check_cache[tbl_to_cache] = get_check_fill_values(conn, tbl_to_cache)
                except Exception:
                    check_cache[tbl_to_cache] = {}

        # Cache FK constraints for the target table
        if table not in fk_cache:
            try:
                fk_cache[table] = _get_fk_constraints(conn, table)
            except Exception:
                fk_cache[table] = []

        # Also cache for any seed tables and EXISTS-referenced tables
        # Pre-parse EXISTS for referenced tables
        _exists_tables = set()
        for em in re.finditer(
            r"EXISTS\s*\(\s*(?:WITH\s+RECURSIVE\s+\w+(?:\([^)]*\))?\s+AS\s*\()?.*?"
            r"SELECT\s+\S+\s+FROM\s+([\w.]+)",
            policy_sql, re.IGNORECASE | re.DOTALL,
        ):
            _exists_tables.add(em.group(1))
        for tc in test_case_list:
            for tbl in list(tc.get("seed_rows", {}).keys()) + list(_exists_tables):
                if tbl not in nn_cache:
                    try:
                        nn_cache[tbl] = get_not_null_columns(conn, tbl)
                    except Exception:
                        nn_cache[tbl] = {}
                if tbl not in all_cols_cache:
                    try:
                        all_cols_cache[tbl] = get_all_columns(conn, tbl)
                    except Exception:
                        all_cols_cache[tbl] = {}
                if tbl not in check_cache:
                    try:
                        check_cache[tbl] = get_check_fill_values(conn, tbl)
                    except Exception:
                        check_cache[tbl] = {}

        # Run each test case
        item_results = []
        for tc in test_case_list:
            result = run_single_test(
                conn, args, table, tc, policy_sql, nn_cache, all_cols_cache,
                fk_constraints=fk_cache.get(table, []),
                check_cache=check_cache,
            )
            item_results.append(asdict(result))
            total_cases += 1
            if result.passed:
                total_passed += 1
            if result.error:
                total_errors += 1

        results.append({
            "id": item_id,
            "target_table": table,
            "operation": operation,
            "test_results": item_results,
        })

        if (i + 1) % 50 == 0 or (i + 1) == len(test_cases):
            logger.info(
                "[%d/%d] passed=%d/%d, errors=%d",
                i + 1, len(test_cases), total_passed, total_cases, total_errors,
            )

    # Compute metrics
    metrics = compute_metrics(results)
    logger.info("=== Metrics ===")
    for k, v in metrics.items():
        logger.info("  %s: %s", k, v)

    # Save results
    output = {
        "mode": args.mode,
        "metrics": metrics,
        "item_results": results,
    }
    with open(args.output_path, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    logger.info("Saved to %s", args.output_path)

    # Restore original data if backup file exists
    import os
    backup_path = os.path.join(
        os.path.dirname(args.benchmark_path),
        "ORIGINAL_TABLE_DATA_BACKUP.sql",
    )
    if os.path.exists(backup_path):
        logger.info("Restoring original data from %s", backup_path)
        try:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("SET session_replication_role = 'replica'")
                # Truncate the tables that will be restored
                cur.execute("TRUNCATE hr.employees CASCADE")
                cur.execute("TRUNCATE operations.documents CASCADE")
                cur.execute("TRUNCATE engineering.projects CASCADE")
            with open(backup_path) as f:
                sql_content = f.read()
            with conn.cursor() as cur:
                cur.execute(sql_content)
            with conn.cursor() as cur:
                cur.execute("SET session_replication_role = 'origin'")
            logger.info("Original data restored successfully")
        except Exception as e:
            logger.warning("Failed to restore original data: %s", e)

    conn.close()


def main():
    parser = argparse.ArgumentParser(description="text2RLS execution evaluator")
    parser.add_argument("--test_cases_path", type=str, required=True)
    parser.add_argument("--benchmark_path", type=str, required=True)
    parser.add_argument("--predictions_path", type=str, default="")
    parser.add_argument("--db_host", type=str, default=os.environ.get("PGHOST", "localhost"))
    parser.add_argument("--db_port", type=int, default=int(os.environ.get("PGPORT", 5432)))
    parser.add_argument("--db_user", type=str, default=os.environ.get("PGUSER", "postgres"))
    parser.add_argument("--db_pass", type=str, default=os.environ.get("PGPASSWORD", "postgres"))
    parser.add_argument("--db_name", type=str, default="rlsbench")
    parser.add_argument("--mode", type=str, default="gold", choices=["gold", "pred"])
    parser.add_argument("--output_path", type=str, default="exec_eval_results.json")
    args = parser.parse_args()
    run_evaluation(args)


if __name__ == "__main__":
    main()
