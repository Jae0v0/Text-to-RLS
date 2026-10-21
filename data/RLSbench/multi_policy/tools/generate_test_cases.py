"""Generate execution-based test cases for text2RLS benchmark.

Reads benchmark JSON + schema SQL, produces test_cases.json with:
- Seed rows (minimal data for each table)
- Session context
- Action SQL
- Expected outcome (success/rls_check_error, row_count, visible/hidden PKs)

Usage:
    python3 data/RLSbench/multi_policy/tools/generate_test_cases.py \
        --benchmark_path cleaned_acbird_rls_policies.json \
        --schema_path cleaned_text2rls_schema.sql \
        --db_host localhost --db_port 5432 --db_user postgres --db_pass postgres \
        --db_name acbird_dev \
        --output_path test_cases.json
"""

import argparse
import json
from datetime import datetime as _dt_cls
import logging
import re
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional, Set, Tuple

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

ALLOWED_SESSION_ATTRS = {
    "app.employee_id",
    "app.user_id",
    "app.customer_id",
    "app.job_role",
    "app.department_id",
    "app.team_id",
    "app.region_id",
    "app.user_clearance_level",
    "app.position_level",
    "app.tenant_id",
}

# Common PK columns per table (used for seed rows)
TABLE_PK_MAP = {
    "hr.employees": "employee_id",
    "hr.departments": "department_id",
    "hr.payroll": "payroll_id",
    "hr.attendance": "attendance_id",
    "hr.benefits": "benefit_id",
    "hr.performance": "review_id",
    "hr.salary_history": "history_id",
    "hr.shifts": "shift_id",
    "hr.teams": "team_id",
    "hr.positions": "position_id",
    "hr.job_history": "history_id",
    "hr.employee_allowances": "allowance_id",
    "finance.expenses": "expense_id",
    "finance.budget": "budget_id",
    "finance.payroll": "payroll_id",
    "finance.revenue": "revenue_id",
    "finance.tax_records": "tax_id",
    "finance.balance_sheet": "record_id",
    "finance.bank_accounts": "account_id",
    "finance.account_transactions": "transaction_id",
    "engineering.projects": "project_id",
    "engineering.issues": "issue_id",
    "engineering.pull_requests": "pr_id",
    "engineering.code_repository": "repo_id",
    "engineering.builds": "build_id",
    "engineering.releases": "release_id",
    "engineering.tests": "test_id",
    "engineering.pr_comments": "comment_id",
    "operations.audit_logs": "log_id",
    "operations.documents": "document_id",
    "operations.backups": "backup_id",
    "operations.system_config": "config_id",
    "operations.security_events": "event_id",
    "operations.temporal_access": "access_id",
    "operations.business_hours_config": "config_id",
    "operations.holidays": "holiday_id",
    "operations.entity_approval_history": "approval_history_id",
    "operations.entity_assignments": "assignment_id",
    "operations.entity_attachments": "attachment_id",
    "operations.entity_audit_events": "audit_event_id",
    "operations.entity_notes": "note_id",
    "operations.entity_status_history": "status_history_id",
    "operations.sensitive_access_audit": "sensitive_access_id",
    "product.features": "feature_id",
    "product.analytics": "analytic_id",
    "product.metrics": "metric_id",
    "product.roadmap": "roadmap_id",
    "product.user_feedback": "feedback_id",
    "product.feature_usage": "usage_id",
    "product.feature_dependencies": "dependency_id",
    "sales.customers": "customer_id",
    "sales.orders": "order_id",
    "sales.invoices": "invoice_id",
    "sales.contracts": "contract_id",
    "sales.sales_pipeline": "pipeline_id",
    "sales.customer_communications": "comm_id",
    "sales.customer_onboarding": "onboarding_id",
    "sales.regions": "region_id",
    "auth.users": "user_id",
    "auth.access_grants": "grant_id",
    "auth.tenants": "tenant_id",
    "auth.tenant_memberships": "membership_id",
    "auth.organizations": "organization_id",
    "auth.business_units": "business_unit_id",
    "auth.table_scopes": "schema_name",  # composite PK: (schema_name, table_name)
    "common.regions": "region_id",
    "common.security_levels": "level_id",
    "support.call_recordings": "recording_id",
}


# ---------------------------------------------------------------------------
# SQL Parsing
# ---------------------------------------------------------------------------

def extract_session_attrs(sql: str) -> List[str]:
    """Extract current_setting('app.xxx') references from SQL."""
    return list(set(
        m.group(1) for m in re.finditer(r"current_setting\('(app\.[^']+)'", sql)
    ))


def extract_target_table(sql: str) -> Optional[str]:
    """Extract ON schema.table from CREATE POLICY."""
    m = re.search(r'\bON\s+(\w+\.\w+)', sql, re.IGNORECASE)
    return m.group(1).lower() if m else None


def extract_operation(sql: str) -> Optional[str]:
    """Extract FOR SELECT|INSERT|UPDATE|DELETE|ALL."""
    m = re.search(r'\bFOR\s+(SELECT|INSERT|UPDATE|DELETE|ALL)\b', sql, re.IGNORECASE)
    return m.group(1).upper() if m else None


def extract_using_clause(sql: str) -> Optional[str]:
    """Extract USING(...) clause content."""
    return _extract_paren_clause(sql, r'\bUSING\s*\(')


def extract_with_check_clause(sql: str) -> Optional[str]:
    """Extract WITH CHECK(...) clause content."""
    return _extract_paren_clause(sql, r'\bWITH\s+CHECK\s*\(')


def _extract_paren_clause(sql: str, pattern: str) -> Optional[str]:
    m = re.search(pattern, sql, re.IGNORECASE)
    if not m:
        return None
    start = m.end() - 1
    depth = 0
    for i in range(start, len(sql)):
        if sql[i] == '(':
            depth += 1
        elif sql[i] == ')':
            depth -= 1
            if depth == 0:
                return sql[start + 1:i].strip()
    return None


def extract_column_conditions(clause: str, table: str) -> List[Dict[str, str]]:
    """Extract column = value / column = session_attr conditions from a clause.

    Returns list of dicts: {column, operator, value_type, value}
    """
    if not clause:
        return []
    conditions = []

    # Pattern: column_name = literal or column_name = current_setting(...)
    # Also handles: column_name IS NOT NULL, column_name = true/false, etc.
    #
    # Pre-process: strip EXISTS/NOT EXISTS subqueries to prevent
    # their internal conditions from being parsed as top-level conditions.
    def _strip_exists_blocks(sql):
        result = sql
        for pattern in [r'NOT\s+EXISTS\s*\(', r'EXISTS\s*\(']:
            while True:
                m = re.search(pattern, result, re.IGNORECASE)
                if not m:
                    break
                start = m.start()
                paren_start = result.index('(', m.end() - 1)
                depth = 0
                end = paren_start
                for i in range(paren_start, len(result)):
                    if result[i] == '(':
                        depth += 1
                    elif result[i] == ')':
                        depth -= 1
                        if depth == 0:
                            end = i + 1
                            break
                # Replace the EXISTS block with TRUE (keeps AND structure intact)
                result = result[:start] + 'TRUE' + result[end:]
        return result

    clause = _strip_exists_blocks(clause)

    # Also strip IN (SELECT/WITH ...) subqueries
    # Pattern: column IN (SELECT/WITH ...)
    def _strip_in_subqueries(sql):
        result = sql
        while True:
            m = re.search(r'IN\s*\(\s*(?:SELECT|WITH)\b', result, re.IGNORECASE)
            if not m:
                break
            # Find the opening paren
            paren_start = result.index('(', m.start())
            depth = 0
            end = paren_start
            for i in range(paren_start, len(result)):
                if result[i] == '(':
                    depth += 1
                elif result[i] == ')':
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            # Replace with = 1 — keeps the column reference as simple equality
            result = result[:m.start()] + "= 1" + result[end:]
        return result

    clause = _strip_in_subqueries(clause)

    # Also strip scalar subqueries: value OP (SELECT ...)
    def _strip_scalar_subqueries(sql):
        result = sql
        while True:
            m = re.search(r'[><=!]+\s*\(\s*SELECT', result, re.IGNORECASE)
            if not m:
                break
            paren_start = result.index('(', m.start())
            depth = 0
            end = paren_start
            for i in range(paren_start, len(result)):
                if result[i] == '(':
                    depth += 1
                elif result[i] == ')':
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            result = result[:m.start()] + '> 0' + result[end:]
        return result

    clause = _strip_scalar_subqueries(clause)

    # Also strip function calls like ANY(func(...))
    def _strip_func_calls(sql):
        result = sql
        # Replace = ANY(function_call(...)) with = 'placeholder'
        result = re.sub(
            r"=\s*ANY\s*\([^)]*\([^)]*\)[^)]*\)",
            "= 'placeholder'",
            result,
            flags=re.IGNORECASE,
        )
        return result

    clause = _strip_func_calls(clause)

    # Pre-process: protect BETWEEN ... AND ... from being split.
    # Replace "BETWEEN X AND Y" with "BETWEEN X __AND__ Y" so that
    # the AND splitter doesn't break it.
    protected = re.sub(
        r'\bBETWEEN\b(.+?)\bAND\b',
        r'BETWEEN\1__AND__',
        clause,
        flags=re.IGNORECASE,
    )
    atoms = re.split(r'\bAND\b', protected, flags=re.IGNORECASE)
    for atom in atoms:
        atom = atom.strip()
        if not atom:
            continue
        # Strip leading/trailing parentheses that wrap sub-expressions
        while atom.startswith('(') and atom.endswith(')'):
            atom = atom[1:-1].strip()
        # Also strip unmatched leading/trailing parens
        while atom.startswith('(') and atom.count('(') > atom.count(')'):
            atom = atom[1:].strip()
        while atom.endswith(')') and atom.count(')') > atom.count('('):
            atom = atom[:-1].strip()

        # Skip TRUE placeholders from EXISTS stripping
        if atom.strip().upper() == "TRUE":
            continue
        # Skip remaining function calls
        if re.match(r"\s*\w+\s*\(", atom) and "current_setting" not in atom.lower():
            continue

        # column = current_setting('app.xxx', true)::int
        # Also handle qualified column refs: schema.table.column
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s*(=|<>|!=|>=|<=|>|<|IS\s+DISTINCT\s+FROM|IS\s+NOT\s+DISTINCT\s+FROM)\s*"
            r"current_setting\('(app\.\w+)'[^)]*\)(?:::\w+)?",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "session",
                "value": m.group(3),
            })
            continue

        # current_setting(...) OP numeric → session threshold (no column)
        m = re.match(
            r"current_setting\('(app\.\w+)'[^)]*\)(?:::\w+)?\s*"
            r"(=|<>|!=|>=|<=|>|<)\s*(\d+)\b",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": "__session__",
                "operator": m.group(2),
                "value_type": "session_threshold",
                "value": m.group(1),
                "threshold": int(m.group(3)),
            })
            continue

        # current_setting(...) = column_name (reversed, unquoted RHS only)
        # Also handle: current_setting(...) OP schema.table.column
        m = re.match(
            r"current_setting\('(app\.\w+)'[^)]*\)(?:::\w+)?\s*"
            r"(=|<>|!=|>=|<=|>|<|IS\s+DISTINCT\s+FROM|IS\s+NOT\s+DISTINCT\s+FROM)\s*"
            r"(?:\w+\.\w+\.)?(\w+)\b",
            atom, re.IGNORECASE,
        )
        if m:
            rhs = m.group(3)
            # Only treat as column reference if RHS is not a keyword/literal/number
            if rhs.lower() not in ("true", "false", "null") and not rhs.isdigit():
                conditions.append({
                    "column": rhs,
                    "operator": m.group(2),
                    "value_type": "session",
                    "value": m.group(1),
                })
                continue

        # current_setting(...) = 'literal' → session constraint (no column)
        m = re.match(
            r"current_setting\('(app\.\w+)'[^)]*\)(?:::\w+)?\s*"
            r"(=|<>|!=)\s*'([^']*)'",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": "__session__",
                "operator": m.group(2),
                "value_type": "session_literal",
                "value": m.group(1),
                "expected_value": m.group(3),
            })
            continue

        # current_setting(...) IN ('val1', 'val2', ...)
        m = re.match(
            r"current_setting\('(app\.\w+)'[^)]*\)(?:::\w+)?\s+IN\s*\(([^)]+)\)",
            atom, re.IGNORECASE,
        )
        if m:
            # Extract first value from the IN list as the expected role
            vals = re.findall(r"'([^']+)'", m.group(2))
            conditions.append({
                "column": "__session__",
                "operator": "IN",
                "value_type": "session_in",
                "value": m.group(1),
                "in_values": vals,
            })
            continue

        # column IS [NOT] DISTINCT FROM 'literal'
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s+(IS\s+DISTINCT\s+FROM|IS\s+NOT\s+DISTINCT\s+FROM)\s*'([^']*)'",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "literal",
                "value": m.group(3),
            })
            continue

        # column = 'literal'
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s*(=|<>|!=)\s*'([^']*)'", atom, re.IGNORECASE)
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "literal",
                "value": m.group(3),
            })
            continue

        # column IN ('val1', 'val2', ...)
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s+IN\s*\(([^)]+)\)", atom, re.IGNORECASE)
        if m:
            vals = re.findall(r"'([^']+)'", m.group(2))
            if vals:
                conditions.append({
                    "column": m.group(1),
                    "operator": "IN",
                    "value_type": "literal_list",
                    "value": vals[0],  # first value for seed generation
                    "in_values": vals,
                })
                continue

        # column = true/false
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s*=\s*(true|false)\b", atom, re.IGNORECASE)
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "=",
                "value_type": "bool",
                "value": m.group(2).lower(),
            })
            continue

        # column >= / <= / > / < numeric or date value
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s*(>=|<=|>|<)\s*(\d+)", atom, re.IGNORECASE)
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "numeric_cmp",
                "value": m.group(3),
            })
            continue

        # column >= / <= (CURRENT_DATE +/- INTERVAL '...') or without parens
        # Also handles column::type cast (e.g., created_at::date)
        # MUST come before the simple temporal pattern to avoid premature match
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)(?:::\w+)?\s*(>=|<=|>|<|=)\s*\(?"
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))"
            r"\s*([+-])\s*INTERVAL\s+'([^']+)'\)?",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "temporal_cmp",
                "value": m.group(3).lower() + "_interval_" + m.group(4),
            })
            continue

        # column >= / <= / > / < current_date / CURRENT_TIMESTAMP / NOW()
        # Simple pattern (no INTERVAL) — fallback after interval match fails
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)(?:::\w+)?\s*(>=|<=|>|<|=)\s*"
            r"(CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\)|CURRENT_TIME)",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": m.group(2),
                "value_type": "temporal_cmp",
                "value": m.group(3).lower(),
            })
            continue

        # column IS NOT NULL
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s+IS\s+NOT\s+NULL", atom, re.IGNORECASE)
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "IS NOT NULL",
                "value_type": "null_check",
                "value": None,
            })
            continue

        # column IS NULL (seed must have NULL for this column)
        m = re.match(r"(?:\w+\.\w+\.)?(\w+)\s+IS\s+NULL\b", atom, re.IGNORECASE)
        if m:
            col_name = m.group(1).lower()
            # Skip if it's a function call result or session variable
            if col_name not in ("current_setting", "coalesce"):
                conditions.append({
                    "column": m.group(1),
                    "operator": "IS NULL",
                    "value_type": "null_check",
                    "value": None,
                })
            continue

        # current_setting(...) IS NOT NULL
        m = re.match(
            r"current_setting\('(app\.\w+)'[^)]*\)\s+IS\s+NOT\s+NULL",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": "__session__",
                "operator": "IS NOT NULL",
                "value_type": "session_check",
                "value": m.group(1),
            })
            continue


        # column BETWEEN current_date AND current_date + INTERVAL '...'
        # (Restored from __AND__ protection above)
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s+BETWEEN\s+"
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))"
            r"\s+__AND__\s+"
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))\s*[+-]\s*INTERVAL\s+'([^']+)'",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "BETWEEN",
                "value_type": "temporal_between",
                "value": m.group(2),
            })
            continue

        # column BETWEEN CURRENT_TIMESTAMP - INTERVAL '...' AND CURRENT_TIMESTAMP
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s+BETWEEN\s+"
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))\s*-\s*INTERVAL\s+'([^']+)'"
            r"\s+__AND__\s+"
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "BETWEEN",
                "value_type": "temporal_between",
                "value": m.group(2),
            })
            continue

        # current_date/timestamp BETWEEN col1 AND col2
        m = re.match(
            r"(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\)|current_date)\s+BETWEEN\s+"
            r"(?:\w+\.\w+\.)?(\w+)\s+__AND__\s+(?:\w+\.\w+\.)?(\w+)",
            atom, re.IGNORECASE,
        )
        if m:
            col1, col2 = m.group(1), m.group(2)
            conditions.append({
                "column": col1,
                "operator": "<=",
                "value_type": "temporal_cmp",
                "value": "current_date",
            })
            conditions.append({
                "column": col2,
                "operator": ">=",
                "value_type": "temporal_cmp",
                "value": "current_date",
            })
            continue

        # column = EXTRACT(YEAR FROM current_date)::int
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s*(=)\s*EXTRACT\s*\(\s*YEAR\s+FROM\s+(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\))\s*\)(?:::int)?",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "=",
                "value_type": "extract_year",
                "value": str(_dt_cls.now().year),
            })
            continue

        # column BETWEEN TIME 'HH:MM' AND TIME 'HH:MM'
        m = re.match(        # column BETWEEN TIME 'HH:MM' AND TIME 'HH:MM'
        
            r"(?:\w+\.\w+\.)?(\w+)\s+BETWEEN\s+"
            r"(?:TIME\s+)?'(\d{2}:\d{2}(?::\d{2})?)'"
            r"\s+__AND__\s+"
            r"(?:TIME\s+)?'(\d{2}:\d{2}(?::\d{2})?)'",
            atom, re.IGNORECASE,
        )
        if m:
            conditions.append({
                "column": m.group(1),
                "operator": "BETWEEN",
                "value_type": "time_between",
                "value": f"{m.group(2)}-{m.group(3)}",
            })
            continue

        # EXTRACT(DOW FROM ...) or EXTRACT(HOUR FROM ...)
        m = re.match(
            r"EXTRACT\s*\(\s*(\w+)\s+FROM\s+(?:CURRENT_DATE|CURRENT_TIMESTAMP|NOW\(\)|CURRENT_TIME)\s*\)"
            r"\s*(=|<>|!=|>=|<=|>|<|IN|BETWEEN)\s*(.*)",
            atom, re.IGNORECASE,
        )
        if m:
            # Can't test this via seed rows, skip
            continue

        # Column comparison: col1 > col2 * value or col1 > col2
        m = re.match(
            r"(?:\w+\.\w+\.)?(\w+)\s*(>=|<=|>|<)\s*"
            r"(?:\w+\.\w+\.)?(\w+)(?:\s*\*\s*([\d.]+))?",
            atom, re.IGNORECASE,
        )
        if m:
            col1, op, col2 = m.group(1), m.group(2), m.group(3)
            factor = float(m.group(4)) if m.group(4) else 1.0
            # Exclude SQL keywords, functions, and common aliases
            sql_keywords = {
                "true", "false", "null", "current_date", "current_time",
                "current_timestamp", "now", "interval", "date", "timestamp",
                "select", "from", "where", "and", "or", "not", "in",
                "exists", "any", "all", "localtime", "localtimestamp",
            }
            if col2.lower() not in sql_keywords and col1.lower() not in sql_keywords:
                conditions.append({
                    "column": col1,
                    "operator": op,
                    "value_type": "col_comparison",
                    "value": col2,
                    "factor": factor,
                })
                continue

    # Post-filter: remove conditions where "column" is actually a SQL keyword
    sql_keywords = {
        "current_time", "current_date", "current_timestamp", "localtime",
        "localtimestamp", "now", "true", "false", "null",
    }
    conditions = [c for c in conditions if c["column"].lower() not in sql_keywords]
    return conditions


def has_exists_subquery(clause: str) -> bool:
    """Check if a clause uses EXISTS subquery."""
    if not clause:
        return False
    return bool(re.search(r'\bEXISTS\s*\(', clause, re.IGNORECASE))


def has_temporal_condition(clause: str) -> bool:
    """Check if clause references time functions."""
    if not clause:
        return False
    return bool(re.search(
        r'\b(CURRENT_DATE|CURRENT_TIME|CURRENT_TIMESTAMP|NOW\(\)|INTERVAL)\b',
        clause, re.IGNORECASE,
    ))


# ---------------------------------------------------------------------------
# Test Case Generation
# ---------------------------------------------------------------------------

def build_positive_session(
    session_attrs: List[str],
    operation: str,
) -> Dict[str, str]:
    """Build a valid session context for positive test cases."""
    session = {}
    for attr in session_attrs:
        name = attr.replace("app.", "")
        if name == "employee_id":
            session[attr] = "100"
        elif name == "user_id":
            session[attr] = "100"
        elif name == "customer_id":
            session[attr] = "200"
        elif name == "job_role":
            session[attr] = "hr_admin"  # will be overridden per item
        elif name == "department_id":
            session[attr] = "10"
        elif name == "team_id":
            session[attr] = "5"
        elif name == "region_id":
            session[attr] = "1"
        elif name == "tenant_id":
            session[attr] = "1"
        elif name == "position_level":
            session[attr] = "5"
        elif name == "user_clearance_level":
            session[attr] = "5"
        else:
            # Try to infer a reasonable default
            if "level" in name:
                session[attr] = "5"
            elif "id" in name:
                session[attr] = "1"
            elif "role" in name:
                session[attr] = "admin"
            else:
                session[attr] = "default_value"
    return session


def build_seed_row_positive(
    table: str,
    conditions: List[Dict],
    session: Dict[str, str],
    pk_val: int = 1,
) -> Dict[str, Any]:
    """Build a seed row that satisfies all conditions (positive case)."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    row = {pk_col: pk_val}

    for cond in conditions:
        col = cond["column"]
        if col == "__session__":
            continue
        op = re.sub(r"\s+", " ", cond["operator"]).upper().strip()
        vtype = cond["value_type"]
        val = cond["value"]

        if vtype == "col_comparison":
            # col1 > col2 * factor → set both columns to satisfy
            from datetime import datetime, timedelta
            col2 = val
            factor = cond.get("factor", 1.0)
            # Check if columns are temporal
            is_ts = any(
                col.endswith(s) or col.startswith(s)
                for s in ("_time", "_at", "_date", "start", "end", "created", "updated")
            )
            if is_ts:
                now = datetime.now()
                if op in (">=", ">"):
                    row[col] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                    row[col2] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                elif op in ("<=", "<"):
                    row[col] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                    row[col2] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
            else:
                if op in (">=", ">"):
                    row[col] = 1000
                    row[col2] = 100
                elif op in ("<=", "<"):
                    row[col] = 10
                    row[col2] = 1000
            continue

        if vtype == "temporal_between":
            # column BETWEEN dates → set to today or within range
            from datetime import date, timedelta
            today = date.today()
            row[col] = str(today)
            continue

        if vtype == "time_between":
            # time between parsing handled at evaluator level
            pass

        if vtype == "session":
            session_val = session.get(val, "100")
            if op in ("IS DISTINCT FROM", "<>", "!="):
                # Column must NOT equal the session value
                row[col] = _mismatch_value(session_val)
            elif op == "IS NOT DISTINCT FROM":
                # Column must equal the session value
                row[col] = _cast_seed_value(session_val)
            else:
                # Column must equal the session value
                row[col] = _cast_seed_value(session_val)
        elif vtype == "literal":
            if op in ("IS DISTINCT FROM", "<>", "!="):
                row[col] = _mismatch_literal(val)
            elif op == "IS NOT DISTINCT FROM":
                row[col] = val  # must equal
            else:
                row[col] = val
        elif vtype == "bool":
            if op in ("IS DISTINCT FROM", "<>", "!="):
                row[col] = val != "true"
            else:
                row[col] = val == "true"
        elif vtype == "literal_list":
            row[col] = val  # first value from IN list
        elif vtype == "numeric_cmp":
            # Satisfy comparison: >= N → use N, <= N → use N, > N → use N+1
            try:
                n = int(val)
                if op in (">=", "<=", "="):
                    row[col] = n
                elif op == ">":
                    row[col] = n + 1
                elif op == "<":
                    row[col] = n - 1
            except ValueError:
                row[col] = val
        elif vtype == "temporal_cmp":
            # Set column to satisfy temporal comparison dynamically
            from datetime import date, datetime, timedelta
            today = date.today()
            now = datetime.now()
            # Check if column is likely a timestamp (not just date)
            is_timestamp = col.endswith("_at") or col.endswith("_time") or "timestamp" in col or col.startswith("start") or col.startswith("end") or col.startswith("last_") or col.startswith("created") or col.startswith("updated")
            # Parse interval from value if present (e.g., "-_interval_7 years")
            interval_days = 365  # default 1 year
            val_str = str(val) if val else ""
            iv_match = re.search(r"_interval_(\d+)\s*(year|month|day|week|hour)", val_str, re.IGNORECASE)
            if iv_match:
                n_units = int(iv_match.group(1))
                unit = iv_match.group(2).lower()
                if unit.startswith("year"):
                    interval_days = n_units * 365
                elif unit.startswith("month"):
                    interval_days = n_units * 30
                elif unit.startswith("week"):
                    interval_days = n_units * 7
                elif unit.startswith("day"):
                    interval_days = n_units
                elif unit.startswith("hour"):
                    interval_days = max(1, n_units // 24)
            # Add margin (50% extra) to ensure we're well within bounds
            margin_days = max(30, interval_days // 2)
            total_days = interval_days + margin_days
            if op in (">=", ">"):
                # column >= current_date - INTERVAL → use recent date within range
                # column >= current_date → use future date
                if "_interval_" in val_str and "-" in val_str:
                    # e.g., column >= current_date - INTERVAL '90 days' → use 30 days ago
                    if is_timestamp:
                        row[col] = (now - timedelta(days=interval_days // 3)).strftime("%Y-%m-%d %H:%M:%S")
                    else:
                        row[col] = str(today - timedelta(days=interval_days // 3))
                else:
                    if is_timestamp:
                        row[col] = (now + timedelta(days=total_days)).strftime("%Y-%m-%d %H:%M:%S")
                    else:
                        row[col] = str(today + timedelta(days=total_days))
            elif op in ("<=", "<"):
                # column <= current_date → use past date
                # column < current_date - INTERVAL '7 years' → use 8+ years ago
                if is_timestamp:
                    row[col] = (now - timedelta(days=total_days)).strftime("%Y-%m-%d %H:%M:%S")
                else:
                    row[col] = str(today - timedelta(days=total_days))
            elif op == "=":
                row[col] = str(today)
        elif vtype == "extract_year":
            # EXTRACT(YEAR FROM current_date) = current year
            row[col] = int(val)
        elif vtype == "null_check":
            if op == "IS NULL":
                row[col] = None
            elif op == "IS NOT NULL":
                # Use a type-safe non-null default based on column name heuristic
                from datetime import date, datetime
                if col.endswith("_date") or col == "date" or col == "hire_date":
                    row[col] = str(date.today())
                elif col.endswith("_at") or col.endswith("_time") or col.endswith("_from") or col.endswith("_to") or col.endswith("_start") or col.endswith("_end"):
                    row[col] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                elif col.startswith("created") or col.startswith("updated") or col.startswith("effective") or col.startswith("start") or col.startswith("end") or col.startswith("last_"):
                    row[col] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                elif col.endswith("_id") or col.endswith("_level") or col == "id":
                    row[col] = 1
                elif col.endswith("_active") or col.startswith("is_"):
                    row[col] = True
                else:
                    row[col] = "placeholder"

    return row


def build_seed_row_negative(
    table: str,
    conditions: List[Dict],
    session: Dict[str, str],
    pk_val: int = 2,
) -> Dict[str, Any]:
    """Build a seed row that violates at least one condition (negative case)."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    row = {pk_col: pk_val}

    violated = False
    for cond in conditions:
        col = cond["column"]
        if col == "__session__":
            continue
        op = re.sub(r"\s+", " ", cond["operator"]).upper().strip()
        vtype = cond["value_type"]
        val = cond["value"]
        is_negated = op in ("IS DISTINCT FROM", "<>", "!=")

        if vtype in ("col_comparison", "temporal_between", "time_between"):
            from datetime import date, datetime, timedelta
            # Handled at evaluator level, fill positive values
            if not violated and vtype == "col_comparison":
                col2 = val
                is_ts = any(
                    col.endswith(s) or col.startswith(s)
                    for s in ("_time", "_at", "_date", "start", "end", "created", "updated")
                )
                now = datetime.now()
                # Violate: make col1 < col2 * factor
                if is_ts:
                    if op in (">=", ">"):
                        row[col] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                        row[col2] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                    elif op in ("<=", "<"):
                        row[col] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                        row[col2] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                else:
                    if op in (">=", ">"):
                        row[col] = 1
                        row[col2] = 10000
                    elif op in ("<=", "<"):
                        row[col] = 10000
                        row[col2] = 1
                violated = True
            elif vtype == "temporal_between":
                if not violated:
                    row[col] = str(date.today() - timedelta(days=3650))
                    violated = True
                else:
                    row[col] = str(date.today())
            continue

        if not violated:
            # Violate the first applicable condition
            if vtype == "session":
                session_val = session.get(val, "100")
                if is_negated:
                    # Positive requires != session; violate by making it equal
                    row[col] = _cast_seed_value(session_val)
                else:
                    # Positive requires == session; violate by mismatching
                    row[col] = _mismatch_value(session_val)
                violated = True
            elif vtype == "literal":
                row[col] = val if is_negated else _mismatch_literal(val)
                violated = True
            elif vtype == "bool":
                if is_negated:
                    row[col] = val == "true"
                else:
                    row[col] = val != "true"
                violated = True
            elif vtype == "literal_list":
                row[col] = _mismatch_literal(val)
                violated = True
            elif vtype == "numeric_cmp":
                try:
                    n = int(val)
                    # Violate: >= N → use N-1, <= N → use N+1, > N → use N, < N → use N
                    if op == ">=":
                        row[col] = n - 1
                    elif op == "<=":
                        row[col] = n + 1
                    elif op == ">":
                        row[col] = n
                    elif op == "<":
                        row[col] = n
                    else:
                        row[col] = n + 999
                except ValueError:
                    row[col] = val
                violated = True
            elif vtype == "extract_year":
                # Violate: use wrong year
                row[col] = int(val) - 1
                violated = True
            elif vtype == "temporal_cmp":
                # Violate temporal: >= current_date → use far past
                from datetime import date, timedelta
                today = date.today()
                if op in (">=", ">"):
                    row[col] = str(today - timedelta(days=365))
                elif op in ("<=", "<"):
                    row[col] = str(today + timedelta(days=365))
                elif op == "=":
                    row[col] = str(today + timedelta(days=365))
                violated = True
            else:
                row[col] = "some_value"
        else:
            # Remaining conditions get positive values
            if vtype == "session":
                session_val = session.get(val, "100")
                row[col] = _mismatch_value(session_val) if is_negated else _cast_seed_value(session_val)
            elif vtype == "literal":
                row[col] = _mismatch_literal(val) if is_negated else val
            elif vtype == "bool":
                row[col] = (val != "true") if is_negated else (val == "true")
            elif vtype == "literal_list":
                row[col] = val  # first value from IN list (positive)
            elif vtype == "numeric_cmp":
                try:
                    n = int(val)
                    if op in (">=", "<=", "="):
                        row[col] = n
                    elif op == ">":
                        row[col] = n + 1
                    elif op == "<":
                        row[col] = n - 1
                except ValueError:
                    row[col] = val
            elif vtype == "temporal_cmp":
                # Positive value for remaining conditions
                from datetime import date, timedelta
                today = date.today()
                if op in (">=", ">"):
                    row[col] = str(today + timedelta(days=365))
                elif op in ("<=", "<"):
                    row[col] = str(today - timedelta(days=365))
                elif op == "=":
                    row[col] = str(today)
            elif vtype == "extract_year":
                row[col] = int(val)

    return row


def build_negative_for_condition(
    table: str,
    conditions: List[Dict],
    session: Dict[str, str],
    violate_idx: int,
    pk_val: int = 2,
) -> Optional[Dict[str, Any]]:
    """Build a seed row violating condition[violate_idx], satisfying all others.

    Returns None if the target condition has no row-level column to violate
    (e.g. session-only conditions like __session__).
    """
    pk_col = TABLE_PK_MAP.get(table, "id")
    row = {pk_col: pk_val}

    target = conditions[violate_idx]
    if target["column"] == "__session__":
        return None  # Can't violate session-only via row data

    from datetime import date, timedelta

    for i, cond in enumerate(conditions):
        col = cond["column"]
        if col == "__session__":
            continue
        op = re.sub(r"\s+", " ", cond["operator"]).upper().strip()
        vtype = cond["value_type"]
        val = cond["value"]
        is_negated = op in ("IS DISTINCT FROM", "<>", "!=")

        if vtype in ("col_comparison", "temporal_between", "time_between"):
            from datetime import datetime as _dt
            is_ts = any(
                col.endswith(s) or col.startswith(s)
                for s in ("_time", "_at", "_date", "start", "end", "created", "updated")
            )
            now = _dt.now()
            if i == violate_idx:
                if vtype == "col_comparison":
                    col2 = val
                    if is_ts:
                        if op in (">=", ">"):
                            row[col] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                            row[col2] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                        elif op in ("<=", "<"):
                            row[col] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                            row[col2] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                    else:
                        if op in (">=", ">"):
                            row[col] = 1
                            row[col2] = 10000
                        elif op in ("<=", "<"):
                            row[col] = 10000
                            row[col2] = 1
                elif vtype == "temporal_between":
                    row[col] = str(date.today() - timedelta(days=3650))
            else:
                if vtype == "col_comparison":
                    col2 = val
                    if is_ts:
                        if op in (">=", ">"):
                            row[col] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                            row[col2] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                        elif op in ("<=", "<"):
                            row[col] = (now - timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                            row[col2] = (now + timedelta(days=365)).strftime("%Y-%m-%d %H:%M:%S")
                    else:
                        if op in (">=", ">"):
                            row[col] = 1000
                            row[col2] = 100
                        elif op in ("<=", "<"):
                            row[col] = 10
                            row[col2] = 1000
                elif vtype == "temporal_between":
                    row[col] = str(date.today())
            continue

        if i == violate_idx:
            # VIOLATE this condition
            if vtype == "session":
                session_val = session.get(val, "100")
                if is_negated:
                    row[col] = _cast_seed_value(session_val)
                else:
                    row[col] = _mismatch_value(session_val)
            elif vtype == "literal":
                row[col] = val if is_negated else _mismatch_literal(val)
            elif vtype == "bool":
                row[col] = (val == "true") if is_negated else (val != "true")
            elif vtype == "literal_list":
                row[col] = _mismatch_literal(val)
            elif vtype == "numeric_cmp":
                try:
                    n = int(val)
                    if op == ">=":
                        row[col] = n - 1
                    elif op == "<=":
                        row[col] = n + 1
                    elif op == ">":
                        row[col] = n
                    elif op == "<":
                        row[col] = n
                    else:
                        row[col] = n + 999
                except ValueError:
                    row[col] = val
            elif vtype == "extract_year":
                row[col] = int(val) - 1
            elif vtype == "temporal_cmp":
                today = date.today()
                if op in (">=", ">"):
                    row[col] = str(today - timedelta(days=365))
                elif op in ("<=", "<"):
                    row[col] = str(today + timedelta(days=365))
                elif op == "=":
                    row[col] = str(today + timedelta(days=365))
            elif vtype == "null_check":
                pass  # omit column → NULL violates IS NOT NULL
            else:
                row[col] = "violate_value"
        else:
            # SATISFY this condition (same logic as build_seed_row_positive)
            if vtype == "session":
                session_val = session.get(val, "100")
                if is_negated:
                    row[col] = _mismatch_value(session_val)
                else:
                    row[col] = _cast_seed_value(session_val)
            elif vtype == "literal":
                if is_negated:
                    row[col] = _mismatch_literal(val)
                else:
                    row[col] = val
            elif vtype == "bool":
                row[col] = (val != "true") if is_negated else (val == "true")
            elif vtype == "literal_list":
                row[col] = val
            elif vtype == "numeric_cmp":
                try:
                    n = int(val)
                    if op in (">=", "<=", "="):
                        row[col] = n
                    elif op == ">":
                        row[col] = n + 1
                    elif op == "<":
                        row[col] = n - 1
                except ValueError:
                    row[col] = val
            elif vtype == "extract_year":
                row[col] = int(val)
            elif vtype == "temporal_cmp":
                today = date.today()
                if op in (">=", ">"):
                    row[col] = str(today + timedelta(days=365))
                elif op in ("<=", "<"):
                    row[col] = str(today - timedelta(days=365))
                elif op == "=":
                    row[col] = str(today)
            elif vtype == "null_check":
                if col.endswith("_date") or col == "date" or col == "hire_date":
                    row[col] = str(date.today())
                elif col.endswith("_at") or col.endswith("_time") or col.endswith("_from") or col.endswith("_to") or col.endswith("_start") or col.endswith("_end"):
                    row[col] = "2025-01-01 00:00:00"
                elif col.startswith("created") or col.startswith("updated") or col.startswith("effective") or col.startswith("start") or col.startswith("end") or col.startswith("last_"):
                    row[col] = "2025-01-01 00:00:00"
                elif col.endswith("_id") or col.endswith("_level") or col == "id":
                    row[col] = 1
                else:
                    row[col] = "placeholder"

    return row


def _cast_seed_value(val: str) -> Any:
    """Cast string session value to appropriate type for seed row."""
    try:
        return int(val)
    except (ValueError, TypeError):
        return val


def _mismatch_value(val: str) -> Any:
    """Return a value that doesn't match the given value."""
    try:
        return int(val) + 999
    except (ValueError, TypeError):
        return f"wrong_{val}"


def _mismatch_literal(val: str) -> str:
    """Return a literal that doesn't match."""
    return f"not_{val}"


def detect_review_issues(
    item: Dict,
    session_attrs: List[str],
    using_clause: Optional[str],
    wc_clause: Optional[str],
) -> List[Dict[str, str]]:
    """Detect review issues per spec."""
    issues = []

    # Non-whitelist session attributes
    for attr in session_attrs:
        if attr not in ALLOWED_SESSION_ATTRS:
            issues.append({
                "issue_type": "out_of_scope_session_attribute",
                "reason": f"Gold SQL uses {attr} which is not in the allowed whitelist",
                "suggested_fix": f"Replace with table column lookup or add {attr} to whitelist",
            })

    # user_id / employee_id mixing
    sql = item.get("sql", "")
    if "app.employee_id" in sql and "user_id" in sql:
        if re.search(r"user_id\s*=\s*current_setting\('app\.employee_id'", sql):
            issues.append({
                "issue_type": "user_employee_identity_mixing",
                "reason": "user_id compared with app.employee_id",
                "suggested_fix": "Use app.user_id for user_id columns, or map via auth.users",
            })

    # Temporal needs mock
    combined = (using_clause or "") + (wc_clause or "")
    if has_temporal_condition(combined):
        issues.append({
            "issue_type": "needs_time_mock",
            "reason": "Policy references CURRENT_DATE/CURRENT_TIMESTAMP",
            "suggested_fix": "Use dynamic seed data with CURRENT_TIMESTAMP offsets",
        })

    return issues


def extract_job_role_from_sql(sql: str) -> Optional[str]:
    """Extract the expected job_role value from gold SQL.

    Handles both equality (= 'role') and IN ('role1', 'role2') patterns.
    Returns the first matching role value.
    """
    # Equality: current_setting('app.job_role') = 'role'
    m = re.search(r"current_setting\('app\.job_role'[^)]*\)\s*=\s*'([^']+)'", sql, re.IGNORECASE)
    if m:
        return m.group(1)
    m = re.search(r"'([^']+)'\s*=\s*current_setting\('app\.job_role'", sql, re.IGNORECASE)
    if m:
        return m.group(1)
    # IN list: current_setting('app.job_role') IN ('role1', 'role2')
    m = re.search(
        r"current_setting\('app\.job_role'[^)]*\)\s+IN\s*\(([^)]+)\)",
        sql, re.IGNORECASE,
    )
    if m:
        vals = re.findall(r"'([^']+)'", m.group(1))
        if vals:
            return vals[0]
    return None


# ---------------------------------------------------------------------------
# Per-Operation Test Case Builders
# ---------------------------------------------------------------------------

def generate_select_tests(
    item: Dict,
    table: str,
    session_attrs: List[str],
    using_conditions: List[Dict],
    session: Dict[str, str],
) -> List[Dict]:
    """Generate test cases for SELECT policy."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    cases = []

    # 1. Positive: row visible
    pos_row = build_seed_row_positive(table, using_conditions, session, pk_val=1)
    pos_pk = pos_row.get(pk_col, 1)
    cases.append({
        "case_id": f"{item['id']}_select_positive",
        "purpose": "positive",
        "description": "Row satisfying all USING conditions should be visible",
        "session": session,
        "mock_time": None,
        "seed_rows": {table: [pos_row]},
        "action": {"type": "SELECT", "sql": f"SELECT * FROM {table};"},
        "expected": {
            "outcome": "success",
            "visible_primary_keys": [pos_pk],
            "hidden_primary_keys": [],
        },
    })

    # 2. Per-condition negative tests: one test per row-level condition
    #    Each violates exactly ONE condition while satisfying all others.
    row_conditions = [
        (i, c) for i, c in enumerate(using_conditions)
        if c["column"] != "__session__"
    ]
    if row_conditions:
        for idx, (cond_idx, cond) in enumerate(row_conditions):
            neg_pk_val = 2 + idx
            neg_row = build_negative_for_condition(
                table, using_conditions, session,
                violate_idx=cond_idx, pk_val=neg_pk_val,
            )
            if neg_row is None:
                continue
            neg_pk = neg_row.get(pk_col, neg_pk_val)
            col_desc = cond["column"]
            cases.append({
                "case_id": f"{item['id']}_select_neg_c{cond_idx}_{col_desc}",
                "purpose": "negative",
                "description": f"Row violating {col_desc} condition should be hidden",
                "session": session,
                "mock_time": None,
                "seed_rows": {table: [pos_row, neg_row]},
                "action": {"type": "SELECT", "sql": f"SELECT * FROM {table};"},
                "expected": {
                    "outcome": "success",
                    "visible_primary_keys": [pos_pk],
                    "hidden_primary_keys": [neg_pk],
                },
            })
    else:
        # Session-only policy: no row-level conditions to violate.
        # Use a wrong-session negative test instead.
        # Find a session attribute to change
        session_conds = [
            c for c in using_conditions
            if c["column"] == "__session__"
            and c["value_type"] in ("session_literal", "session_in", "session_threshold")
        ]
        if session_conds:
            bad_session = dict(session)
            sc = session_conds[0]
            if sc["value_type"] == "session_literal":
                bad_session[sc["value"]] = "wrong_" + sc.get("expected_value", "value")
            elif sc["value_type"] == "session_in":
                bad_session[sc["value"]] = "unauthorized_role"
            elif sc["value_type"] == "session_threshold":
                bad_session[sc["value"]] = "0"
            # With wrong session, the positive row should be hidden
            cases.append({
                "case_id": f"{item['id']}_select_neg_wrong_session",
                "purpose": "negative",
                "description": "Wrong session should hide all rows",
                "session": bad_session,
                "mock_time": None,
                "seed_rows": {table: [pos_row]},
                "action": {"type": "SELECT", "sql": f"SELECT * FROM {table};"},
                "expected": {
                    "outcome": "success",
                    "visible_primary_keys": [],
                    "hidden_primary_keys": [pos_pk],
                },
            })

    # 3. Missing session: should return 0 rows
    if session_attrs:
        cases.append({
            "case_id": f"{item['id']}_select_missing_session",
            "purpose": "missing_session",
            "description": "Missing required session attributes should return 0 rows",
            "session": {},
            "mock_time": None,
            "seed_rows": {table: [pos_row]},
            "action": {"type": "SELECT", "sql": f"SELECT * FROM {table};"},
            "expected": {
                "outcome": "success",
                "visible_primary_keys": [],
                "hidden_primary_keys": [pos_pk],
            },
        })

    return cases


def generate_insert_tests(
    item: Dict,
    table: str,
    session_attrs: List[str],
    wc_conditions: List[Dict],
    session: Dict[str, str],
) -> List[Dict]:
    """Generate test cases for INSERT policy."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    cases = []

    # Build insert row from WITH CHECK conditions
    insert_row = build_seed_row_positive(table, wc_conditions, session, pk_val=100)

    # Also add session-matched columns from WC conditions
    from datetime import date, datetime, timedelta
    for wc in wc_conditions:
        col = wc["column"]
        if col == "__session__":
            continue
        if col not in insert_row:
            vtype = wc["value_type"]
            val = wc["value"]
            op = re.sub(r"\s+", " ", wc["operator"]).upper().strip()
            if vtype == "session":
                session_val = session.get(val, "100")
                if op in ("IS DISTINCT FROM", "<>", "!="):
                    insert_row[col] = _mismatch_value(session_val)
                else:
                    insert_row[col] = _cast_seed_value(session_val)
            elif vtype == "literal":
                if op in ("IS DISTINCT FROM", "<>", "!="):
                    insert_row[col] = _mismatch_literal(val)
                else:
                    insert_row[col] = val
            elif vtype == "bool":
                if op in ("IS DISTINCT FROM", "<>", "!="):
                    insert_row[col] = val != "true"
                else:
                    insert_row[col] = val == "true"
            elif vtype == "null_check":
                if col.endswith("_date") or col == "date":
                    insert_row[col] = str(date.today())
                elif col.endswith("_at") or col.endswith("_time") or col.endswith("_from") or col.endswith("_to"):
                    insert_row[col] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                elif col.startswith("created") or col.startswith("updated") or col.startswith("effective") or col.startswith("start") or col.startswith("end"):
                    insert_row[col] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                elif col.endswith("_id"):
                    insert_row[col] = 1
                else:
                    insert_row[col] = "placeholder"
            elif vtype == "temporal_between":
                insert_row[col] = str(date.today())
            elif vtype == "extract_year":
                insert_row[col] = int(val)
            elif vtype == "temporal_cmp":
                import re as _re
                _iv = _re.search(r"_interval_(\d+)\s*(year|month|day|week)", str(val), _re.IGNORECASE)
                _idays = 365
                if _iv:
                    _n = int(_iv.group(1))
                    _u = _iv.group(2).lower()
                    if _u.startswith("year"): _idays = _n * 365
                    elif _u.startswith("month"): _idays = _n * 30
                    elif _u.startswith("week"): _idays = _n * 7
                    elif _u.startswith("day"): _idays = _n
                _margin = max(30, _idays // 2)
                if op in (">=", ">"):
                    if "_interval_" in str(val) and "-" in str(val):
                        insert_row[col] = str(date.today() - timedelta(days=_idays // 3))
                    else:
                        insert_row[col] = str(date.today() + timedelta(days=_idays + _margin))
                elif op in ("<=", "<"):
                    insert_row[col] = str(date.today() - timedelta(days=_idays + _margin))
                else:
                    insert_row[col] = str(date.today())

    cols = ", ".join(insert_row.keys())
    vals = ", ".join(_sql_literal(v) for v in insert_row.values())

    # 1. Valid insert succeeds
    cases.append({
        "case_id": f"{item['id']}_insert_positive",
        "purpose": "positive",
        "description": "Insert satisfying WITH CHECK should succeed",
        "session": session,
        "mock_time": None,
        "seed_rows": {},
        "action": {
            "type": "INSERT",
            "sql": f"INSERT INTO {table} ({cols}) VALUES ({vals});",
        },
        "expected": {"outcome": "success", "row_count": 1},
    })

    # 2. Per-condition WITH CHECK negatives: violate each row-level condition
    row_wc_conditions = [
        (i, c) for i, c in enumerate(wc_conditions)
        if c["column"] != "__session__"
    ]
    for idx, (cond_idx, cond) in enumerate(row_wc_conditions):
        neg_insert = build_negative_for_condition(
            table, wc_conditions, session,
            violate_idx=cond_idx, pk_val=200 + idx,
        )
        if neg_insert is None:
            continue
        neg_cols = ", ".join(neg_insert.keys())
        neg_vals = ", ".join(_sql_literal(v) for v in neg_insert.values())
        col_desc = cond["column"]
        cases.append({
            "case_id": f"{item['id']}_insert_neg_c{cond_idx}_{col_desc}",
            "purpose": "with_check_negative",
            "description": f"Insert violating {col_desc} should fail WITH CHECK",
            "session": session,
            "mock_time": None,
            "seed_rows": {},
            "action": {
                "type": "INSERT",
                "sql": f"INSERT INTO {table} ({neg_cols}) VALUES ({neg_vals});",
            },
            "expected": {"outcome": "rls_check_error"},
        })

    # 3. Wrong role fails (session-level negative)
    job_role = extract_job_role_from_sql(item.get("sql", ""))
    if job_role and "app.job_role" in session:
        bad_session = dict(session)
        bad_session["app.job_role"] = "unauthorized_role"
        cases.append({
            "case_id": f"{item['id']}_insert_wrong_role",
            "purpose": "role_mismatch",
            "description": "Insert with wrong job_role should fail WITH CHECK",
            "session": bad_session,
            "mock_time": None,
            "seed_rows": {},
            "action": {
                "type": "INSERT",
                "sql": f"INSERT INTO {table} ({cols}) VALUES ({vals});",
            },
            "expected": {"outcome": "rls_check_error"},
        })

    # 4. Missing session fails
    if session_attrs:
        cases.append({
            "case_id": f"{item['id']}_insert_missing_session",
            "purpose": "missing_session",
            "description": "Insert without session attributes should fail",
            "session": {},
            "mock_time": None,
            "seed_rows": {},
            "action": {
                "type": "INSERT",
                "sql": f"INSERT INTO {table} ({cols}) VALUES ({vals});",
            },
            "expected": {"outcome": "rls_check_error"},
        })

    return cases


def generate_delete_tests(
    item: Dict,
    table: str,
    session_attrs: List[str],
    using_conditions: List[Dict],
    session: Dict[str, str],
) -> List[Dict]:
    """Generate test cases for DELETE policy."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    cases = []

    pos_row = build_seed_row_positive(table, using_conditions, session, pk_val=1)
    pos_pk = pos_row.get(pk_col, 1)
    pos_pk_lit = _sql_literal(pos_pk)

    # 1. Allowed row can be deleted
    cases.append({
        "case_id": f"{item['id']}_delete_positive",
        "purpose": "positive",
        "description": "Row satisfying USING should be deletable",
        "session": session,
        "mock_time": None,
        "seed_rows": {table: [pos_row]},
        "action": {
            "type": "DELETE",
            "sql": f"DELETE FROM {table} WHERE {pk_col} = {pos_pk_lit};",
        },
        "expected": {"outcome": "success", "row_count": 1},
    })

    # 2. Per-condition negative tests for DELETE
    row_conditions = [
        (i, c) for i, c in enumerate(using_conditions)
        if c["column"] != "__session__"
    ]
    for idx, (cond_idx, cond) in enumerate(row_conditions):
        neg_pk_val = 2 + idx
        neg_row = build_negative_for_condition(
            table, using_conditions, session,
            violate_idx=cond_idx, pk_val=neg_pk_val,
        )
        if neg_row is None:
            continue
        neg_pk = neg_row.get(pk_col, neg_pk_val)
        neg_pk_lit = _sql_literal(neg_pk)
        col_desc = cond["column"]
        cases.append({
            "case_id": f"{item['id']}_delete_neg_c{cond_idx}_{col_desc}",
            "purpose": "negative",
            "description": f"Row violating {col_desc} should not be deleted",
            "session": session,
            "mock_time": None,
            "seed_rows": {table: [neg_row]},
            "action": {
                "type": "DELETE",
                "sql": f"DELETE FROM {table} WHERE {pk_col} = {neg_pk_lit};",
            },
            "expected": {"outcome": "success", "row_count": 0},
        })

    # 3. Missing session
    if session_attrs:
        cases.append({
            "case_id": f"{item['id']}_delete_missing_session",
            "purpose": "missing_session",
            "description": "Delete without session should affect 0 rows",
            "session": {},
            "mock_time": None,
            "seed_rows": {table: [pos_row]},
            "action": {
                "type": "DELETE",
                "sql": f"DELETE FROM {table} WHERE {pk_col} = {pos_pk_lit};",
            },
            "expected": {"outcome": "success", "row_count": 0},
        })

    return cases


def generate_update_tests(
    item: Dict,
    table: str,
    session_attrs: List[str],
    using_conditions: List[Dict],
    wc_conditions: List[Dict],
    session: Dict[str, str],
) -> List[Dict]:
    """Generate test cases for UPDATE policy (USING + WITH CHECK)."""
    pk_col = TABLE_PK_MAP.get(table, "id")
    cases = []

    # Seed row satisfies USING (to be visible).
    # UPDATE SQL sets WITH CHECK columns to their required values,
    # so the new (post-update) row passes WITH CHECK.
    pos_row = build_seed_row_positive(table, using_conditions, session, pk_val=1)

    # Also add non-conflicting WITH CHECK columns to seed row
    using_col_set = {c["column"] for c in using_conditions if c["column"] != "__session__"}
    for wc in wc_conditions:
        col = wc["column"]
        if col == "__session__" or col in using_col_set:
            continue
        wc_row = build_seed_row_positive(table, [wc], session, pk_val=1)
        if col in wc_row:
            pos_row[col] = wc_row[col]

    pos_pk = pos_row.get(pk_col, 1)

    # Build UPDATE SET clause from WITH CHECK conditions
    wc_set_parts = []
    wc_row_vals = build_seed_row_positive(table, wc_conditions, session, pk_val=1)
    for wc in wc_conditions:
        col = wc["column"]
        if col == "__session__" or col == pk_col:
            continue
        # Ensure we have a value for every WC column
        if col not in wc_row_vals:
            vtype = wc["value_type"]
            val = wc["value"]
            op = re.sub(r"\s+", " ", wc["operator"]).upper().strip()
            if vtype == "session":
                session_val = session.get(val, "100")
                wc_row_vals[col] = _cast_seed_value(session_val) if op not in ("IS DISTINCT FROM", "<>", "!=") else _mismatch_value(session_val)
            elif vtype == "literal":
                wc_row_vals[col] = val if op not in ("IS DISTINCT FROM", "<>", "!=") else _mismatch_literal(val)
            elif vtype == "bool":
                wc_row_vals[col] = (val == "true") if op not in ("IS DISTINCT FROM", "<>", "!=") else (val != "true")
        if col in wc_row_vals:
            wc_set_parts.append(f"{col} = {_sql_literal(wc_row_vals[col])}")

    # Find a safe column to update (not in conditions, not PK)
    condition_cols = {c["column"] for c in using_conditions + wc_conditions}
    safe_update_col = None
    for col in pos_row:
        if col != pk_col and col not in condition_cols:
            safe_update_col = col
            break

    # Build update SQL: prefer WC set parts, fallback to safe column
    # Deduplicate SET columns (can happen when same column in USING and WC)
    seen_cols = set()
    deduped_set = []
    for part in wc_set_parts:
        col_name = part.split("=")[0].strip()
        if col_name not in seen_cols:
            seen_cols.add(col_name)
            deduped_set.append(part)
    wc_set_parts = deduped_set

    pos_pk_lit = _sql_literal(pos_pk)
    if wc_set_parts:
        set_clause = ", ".join(wc_set_parts)
        update_sql = f"UPDATE {table} SET {set_clause} WHERE {pk_col} = {pos_pk_lit};"
    elif safe_update_col:
        update_sql = f"UPDATE {table} SET {safe_update_col} = {safe_update_col} WHERE {pk_col} = {pos_pk_lit};"
    else:
        update_sql = f"UPDATE {table} SET updated_at = NOW() WHERE {pk_col} = {pos_pk_lit};"

    # 1. using_positive + with_check_positive: should succeed
    cases.append({
        "case_id": f"{item['id']}_update_positive",
        "purpose": "positive",
        "description": "Old row satisfies USING, updated row satisfies WITH CHECK",
        "session": session,
        "mock_time": None,
        "seed_rows": {table: [pos_row]},
        "action": {"type": "UPDATE", "sql": update_sql},
        "expected": {"outcome": "success", "row_count": 1},
    })

    # 2. Per-condition USING negatives
    row_conditions = [
        (i, c) for i, c in enumerate(using_conditions)
        if c["column"] != "__session__"
    ]
    for idx, (cond_idx, cond) in enumerate(row_conditions):
        neg_pk_val = 2 + idx
        neg_row = build_negative_for_condition(
            table, using_conditions, session,
            violate_idx=cond_idx, pk_val=neg_pk_val,
        )
        if neg_row is None:
            continue
        neg_pk = neg_row.get(pk_col, neg_pk_val)
        neg_pk_lit = _sql_literal(neg_pk)
        col_desc = cond["column"]
        cases.append({
            "case_id": f"{item['id']}_update_neg_c{cond_idx}_{col_desc}",
            "purpose": "negative",
            "description": f"Row violating {col_desc} in USING should not be updatable",
            "session": session,
            "mock_time": None,
            "seed_rows": {table: [neg_row]},
            "action": {
                "type": "UPDATE",
                "sql": f"UPDATE {table} SET updated_at = NOW() WHERE {pk_col} = {neg_pk_lit};",
            },
            "expected": {"outcome": "success", "row_count": 0},
        })

    # 3. Per-condition WITH CHECK negatives (scope escape tests)
    scope_cols = [c for c in wc_conditions if c["value_type"] == "session"]
    for sc_idx, sc in enumerate(scope_cols):
        escape_col = sc["column"]
        escape_op = sc["operator"].upper()
        session_val = session.get(sc["value"], "1")
        if escape_op in ("IS DISTINCT FROM", "<>", "!="):
            escape_val = _cast_seed_value(session_val)
        else:
            escape_val = _mismatch_value(session_val)
        cases.append({
            "case_id": f"{item['id']}_update_wc_neg_{escape_col}",
            "purpose": "with_check_negative",
            "description": f"Updating {escape_col} to escape scope should fail WITH CHECK",
            "session": session,
            "mock_time": None,
            "seed_rows": {table: [pos_row]},
            "action": {
                "type": "UPDATE",
                "sql": f"UPDATE {table} SET {escape_col} = {_sql_literal(escape_val)} WHERE {pk_col} = {pos_pk_lit};",
            },
            "expected": {"outcome": "rls_check_error"},
        })

    # 4. Missing session
    if session_attrs:
        cases.append({
            "case_id": f"{item['id']}_update_missing_session",
            "purpose": "missing_session",
            "description": "Update without session should affect 0 rows or fail",
            "session": {},
            "mock_time": None,
            "seed_rows": {table: [pos_row]},
            "action": {"type": "UPDATE", "sql": update_sql},
            "expected": {"outcome": "success", "row_count": 0},
        })

    return cases


def _sql_literal(val: Any) -> str:
    """Convert a Python value to a SQL literal string."""
    if val is None:
        return "NULL"
    if isinstance(val, bool):
        return "true" if val else "false"
    if isinstance(val, (int, float)):
        return str(val)
    return f"'{val}'"


# ---------------------------------------------------------------------------
# Main Generator
# ---------------------------------------------------------------------------

def generate_test_cases_for_item(item: Dict) -> Dict:
    """Generate test cases for a single benchmark item."""
    sql = item.get("sql", "")
    item_id = item["id"]

    target_table = extract_target_table(sql)
    operation = extract_operation(sql)
    session_attrs = extract_session_attrs(sql)
    using_clause = extract_using_clause(sql)
    wc_clause = extract_with_check_clause(sql)
    using_conditions = extract_column_conditions(using_clause, target_table)
    wc_conditions = extract_column_conditions(wc_clause, target_table)

    # Build session
    session = build_positive_session(session_attrs, operation)
    # Override job_role if found in SQL
    job_role = extract_job_role_from_sql(sql)
    if job_role and "app.job_role" in session:
        session["app.job_role"] = job_role

    # Adjust session values for session literal conditions
    # e.g., current_setting('app.job_role') = 'cfo' → set to 'cfo'
    all_conditions = using_conditions + wc_conditions
    for cond in all_conditions:
        if cond["value_type"] == "session_literal":
            attr = cond["value"]
            expected = cond.get("expected_value", "")
            if expected and attr in session:
                op = cond.get("operator", "=")
                if op in ("=",):
                    session[attr] = expected
        elif cond["value_type"] == "session_in":
            attr = cond["value"]
            vals = cond.get("in_values", [])
            if vals and attr in session:
                session[attr] = vals[0]
        elif cond["value_type"] == "session_threshold":
            attr = cond["value"]
            op = cond["operator"]
            threshold = cond["threshold"]
            if op in (">=", "="):
                session[attr] = str(threshold)
            elif op == ">":
                session[attr] = str(threshold + 1)
            elif op in ("<=",):
                session[attr] = str(threshold)
            elif op == "<":
                session[attr] = str(threshold - 1)

    # Detect review issues
    review_issues = detect_review_issues(item, session_attrs, using_clause, wc_clause)

    # Generate test cases by operation
    test_cases = []
    if operation == "SELECT":
        test_cases = generate_select_tests(
            item, target_table, session_attrs, using_conditions, session,
        )
    elif operation == "INSERT":
        test_cases = generate_insert_tests(
            item, target_table, session_attrs, wc_conditions, session,
        )
    elif operation == "DELETE":
        test_cases = generate_delete_tests(
            item, target_table, session_attrs, using_conditions, session,
        )
    elif operation == "UPDATE":
        test_cases = generate_update_tests(
            item, target_table, session_attrs,
            using_conditions, wc_conditions, session,
        )
    elif operation == "ALL":
        # FOR ALL → generate both SELECT-like and INSERT-like tests
        test_cases = generate_select_tests(
            item, target_table, session_attrs, using_conditions, session,
        )
        test_cases += generate_insert_tests(
            item, target_table, session_attrs, wc_conditions, session,
        )

    # Pre/post/invariant conditions
    pre_conditions = [
        f"{c['column']} {c['operator']} {c['value']}"
        for c in using_conditions if c["column"] != "__session__"
    ]
    post_conditions = [
        f"{c['column']} {c['operator']} {c['value']}"
        for c in wc_conditions if c["column"] != "__session__"
    ]
    invariant_conditions = [
        f"{c['value']} IS NOT NULL"
        for c in using_conditions + wc_conditions
        if c["value_type"] == "session_check"
    ] + [
        f"{c['value']} = {c['column']}"
        for c in (using_conditions + wc_conditions)
        if c["value_type"] == "session" and c["operator"] == "="
        and c in wc_conditions and c in using_conditions
    ]

    return {
        "id": item_id,
        "target_table": target_table,
        "operation": operation,
        "test_design_summary": (
            f"{operation} policy on {target_table} with "
            f"{len(using_conditions)} USING conditions, "
            f"{len(wc_conditions)} WITH CHECK conditions, "
            f"{len(session_attrs)} session attrs"
        ),
        "pre_row_conditions": pre_conditions,
        "post_row_conditions": post_conditions,
        "invariant_conditions": invariant_conditions,
        "review_issues": review_issues,
        "test_cases": test_cases,
    }


def main():
    parser = argparse.ArgumentParser(description="Generate text2RLS test cases")
    parser.add_argument("--benchmark_path", type=str, required=True)
    parser.add_argument("--schema_path", type=str, required=True)
    parser.add_argument("--output_path", type=str, default="test_cases.json")
    args = parser.parse_args()

    logger.info(f"Loading benchmark from {args.benchmark_path}")
    with open(args.benchmark_path) as f:
        benchmark = json.load(f)
    logger.info(f"Loaded {len(benchmark)} items")

    results = []
    errors = 0
    for item in benchmark:
        try:
            tc = generate_test_cases_for_item(item)
            results.append(tc)
        except Exception as e:
            logger.error(f"Item {item['id']}: {e}")
            errors += 1
            results.append({
                "id": item["id"],
                "target_table": None,
                "operation": None,
                "test_design_summary": f"ERROR: {e}",
                "review_issues": [{"issue_type": "generation_error", "reason": str(e)}],
                "test_cases": [],
            })

    with open(args.output_path, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    # Summary
    total_cases = sum(len(r["test_cases"]) for r in results)
    items_with_issues = sum(1 for r in results if r.get("review_issues"))
    logger.info(
        f"Done. {len(results)} items, {total_cases} test cases, "
        f"{items_with_issues} items with review issues, {errors} errors"
    )
    logger.info(f"Saved to {args.output_path}")


if __name__ == "__main__":
    main()
