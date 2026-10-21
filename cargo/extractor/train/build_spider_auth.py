"""Build the Authorization-Template (AT) channel of the supervision corpus by
instantiating typed authorization patterns (ownership, RBAC, ABAC, CBAC, ReBAC, MAC)
on Spider schemas. Spider schemas provide diverse relational structures and schema
identifiers, with no overlap to the RLSbench evaluation set.
Pattern slices (paper §IV-B taxonomy):
  - Role-based AT slice  (|O|~2.8, single-table, standard RLS)
  - Cross-table AT slice (|O|~4.8, moderate complexity)
  - Bulk-standard slice  (|O|~1.9, common patterns)
  - Hierarchical slice   (|O|~6.2, recursive / multi-hop)
  - tpl level   (|O|~1.0, simple ownership/global)
  - ct level    (|O|~7.7, contrastive cross-tenant)

Usage:
  python3 cargo/extractor/train/build_spider_auth.py \
    --spider-schemas data/spider_schemas.jsonl \
    --out data/spider_auth_templates.jsonl \
    --seed 42
"""
from __future__ import annotations

import argparse
import json
import random
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# ---------------------------------------------------------------------------
# Schema parsing
# ---------------------------------------------------------------------------

@dataclass
class Column:
    name: str
    is_pk: bool = False

@dataclass
class Table:
    full_name: str
    columns: List[Column] = field(default_factory=list)

    @property
    def short_name(self) -> str:
        parts = self.full_name.split(".")
        return parts[-1] if parts else self.full_name

    def col_names(self) -> List[str]:
        return [c.name for c in self.columns]

@dataclass
class SchemaInfo:
    tables: List[Table] = field(default_factory=list)
    raw: str = ""

    def table_by_short(self, name: str) -> Optional[Table]:
        nl = name.lower()
        for t in self.tables:
            if t.short_name.lower() == nl:
                return t
        return None


def parse_schema(schema_text: str) -> SchemaInfo:
    info = SchemaInfo(raw=schema_text)
    for m in re.finditer(r"#\s*(\S+?):\s*(.+)", schema_text):
        table_name = m.group(1)
        col_strs = [c.strip() for c in m.group(2).split(",") if c.strip()]
        cols = []
        for cs in col_strs:
            is_pk = cs.endswith("*")
            cname = cs.rstrip("*").strip()
            if cname:
                cols.append(Column(name=cname, is_pk=is_pk))
        info.tables.append(Table(full_name=table_name, columns=cols))
    return info


# ---------------------------------------------------------------------------
# Column classifier
# ---------------------------------------------------------------------------

USER_KEYWORDS = {
    "user_id", "owner", "owner_id", "author", "author_id", "creator",
    "created_by", "manager_id", "employee_id", "member_id", "student_id",
    "player_id", "person_id", "customer_id", "driver_id", "doctor_id",
    "teacher_id", "assigned_to", "reviewer_id", "approver_id", "seller_id",
    "buyer_id", "sender_id", "receiver_id", "host_id", "guest_id",
    "patient_id", "coach_id", "pilot_id", "captain_id", "worker_id",
    "staff_id", "agent_id", "leader_id", "head_id", "supervisor_id",
    "userid", "playerid", "memberid", "employeeid", "managerid",
    "authorid", "ownerid", "studentid",
}

ROLE_KEYWORDS = {
    "role", "role_code", "type", "category", "department", "dept",
    "department_id", "dept_id", "dept_name", "dept_code", "group",
    "team", "team_id", "position", "class", "level", "rank", "title",
    "job_id", "job_title", "division",
}

STATUS_KEYWORDS = {
    "status", "state", "active", "is_active", "approved", "pending",
    "draft", "deleted", "archived", "completed", "cancelled", "closed",
    "order_status", "order_status_code", "fault_status", "payment_status",
    "is_deleted", "is_approved", "is_published",
}

TIME_KEYWORDS = {
    "date", "time", "datetime", "timestamp", "created_at", "updated_at",
    "start_date", "end_date", "start_time", "end_time", "hire_date",
    "birth_date", "expiry", "expires_at", "deadline", "due_date",
    "date_from", "date_to", "last_update", "year", "month",
    "contract_start_date", "contract_end_date", "registration_date",
    "date_became_customer", "date_of_registration",
}

FK_SUFFIXES = {"_id", "id", "_code", "_num"}


def classify_column(col_name: str) -> Set[str]:
    cl = col_name.lower()
    tags = set()
    if cl in USER_KEYWORDS or any(cl.endswith(f"_{kw}") for kw in {"id", "by"} if "user" in cl or "owner" in cl or "author" in cl or "creator" in cl or "manager" in cl or "employee" in cl or "member" in cl or "player" in cl or "student" in cl or "customer" in cl):
        tags.add("user")
    if cl in USER_KEYWORDS:
        tags.add("user")
    if cl in ROLE_KEYWORDS:
        tags.add("role")
    if cl in STATUS_KEYWORDS:
        tags.add("status")
    if cl in TIME_KEYWORDS or any(kw in cl for kw in ["date", "time", "year", "month", "created", "updated", "expir"]):
        tags.add("time")
    if any(cl.endswith(suf) for suf in FK_SUFFIXES) and cl not in {"id"}:
        tags.add("fk")
    return tags


@dataclass
class SchemaProfile:
    schema: SchemaInfo
    user_cols: List[Tuple[str, str]] = field(default_factory=list)
    role_cols: List[Tuple[str, str]] = field(default_factory=list)
    status_cols: List[Tuple[str, str]] = field(default_factory=list)
    time_cols: List[Tuple[str, str]] = field(default_factory=list)
    fk_cols: List[Tuple[str, str]] = field(default_factory=list)
    n_tables: int = 0
    n_columns: int = 0

    @property
    def score(self) -> int:
        return sum([
            len(self.user_cols) > 0,
            len(self.role_cols) > 0,
            len(self.status_cols) > 0,
            len(self.time_cols) > 0,
            self.n_tables >= 2,
        ])


def profile_schema(info: SchemaInfo) -> SchemaProfile:
    prof = SchemaProfile(schema=info, n_tables=len(info.tables))
    for tbl in info.tables:
        for col in tbl.columns:
            prof.n_columns += 1
            tags = classify_column(col.name)
            pair = (tbl.full_name, col.name)
            if "user" in tags:
                prof.user_cols.append(pair)
            if "role" in tags:
                prof.role_cols.append(pair)
            if "status" in tags:
                prof.status_cols.append(pair)
            if "time" in tags:
                prof.time_cols.append(pair)
            if "fk" in tags:
                prof.fk_cols.append(pair)
    return prof


# ---------------------------------------------------------------------------
# NL requirement templates
# ---------------------------------------------------------------------------

ROLES = [
    "employees", "managers", "administrators", "analysts", "engineers",
    "specialists", "officers", "coordinators", "supervisors", "directors",
    "auditors", "accountants", "consultants", "technicians", "operators",
]

CRUD_OPS = {
    "SELECT": ["view", "read", "access", "see", "retrieve"],
    "INSERT": ["create", "add", "insert", "submit"],
    "UPDATE": ["update", "modify", "edit", "change"],
    "DELETE": ["delete", "remove", "discard"],
}

TIME_CONDITIONS = [
    ("during business hours (09:00-18:00)", "current_time"),
    ("during weekday business hours (09:00-18:00, Monday-Friday)", "current_time"),
    ("only during maintenance windows (02:00-06:00)", "current_time"),
    ("during extended hours (07:00-22:00)", "current_time"),
    ("only after their hire date", "current_date"),
    ("only within the current fiscal year", "current_date"),
]

STATUS_VALUES = [
    "active", "draft", "pending", "approved", "completed",
    "archived", "closed", "open", "in progress", "cancelled",
    "published", "rejected", "suspended", "expired", "voided",
]


def _table_readable(name: str) -> str:
    short = name.split(".")[-1]
    return short.replace("_", " ").lower()


def _col_readable(name: str) -> str:
    return name.replace("_", " ").lower()


# ---------------------------------------------------------------------------
# Template generators — each returns (nl, T, S_list, O_list, E_list, cmd)
# ---------------------------------------------------------------------------

def gen_ownership_simple(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """tpl-level: simple ownership, |O|=1"""
    if not prof.user_cols:
        return None
    tbl_name, user_col = rng.choice(prof.user_cols)
    tbl = prof.schema.table_by_short(tbl_name.split(".")[-1])
    if tbl is None:
        return None
    cmd = rng.choice(["SELECT", "INSERT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    tbl_read = _table_readable(tbl_name)

    nl_variants = [
        f"Users can only {verb} their own {tbl_read} records.",
        f"Each user can only {verb} {tbl_read} entries belonging to them.",
        f"A user can {verb} only their own {tbl_read} records.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: app.user_id\nO: {tbl.full_name}.{user_col}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_tpl",
        "pattern": "ownership_simple",
    }


def gen_ownership_global(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """tpl-level: global read, |O|=0"""
    if not prof.schema.tables:
        return None
    tbl = rng.choice(prof.schema.tables)
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl.full_name)

    nl_variants = [
        f"All {role} can view all {tbl_read} records without restriction.",
        f"Anyone can read all {tbl_read} records.",
        f"{role.capitalize()} have unrestricted read access to {tbl_read}.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": "SELECT",
        "target_text": "S: app.user_id\nO: \nE: ",
        "stage": "anchor",
        "source": "spider_auth_tpl",
        "pattern": "global_read",
    }


def gen_rbac_standard(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """Role-based AT slice: |O|=2-5 (target mean ~2.8)."""
    tbl = rng.choice(prof.schema.tables)
    if len(tbl.columns) < 3:
        return None
    cmd = rng.choice(["SELECT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl.full_name)

    non_pk_cols = [c for c in tbl.columns if not c.is_pk]
    if not non_pk_cols or len(non_pk_cols) < 2:
        non_pk_cols = tbl.columns
    if len(non_pk_cols) < 2:
        return None

    n_o = rng.randint(2, min(5, len(non_pk_cols)))
    o_cols = rng.sample(non_pk_cols, n_o)
    o_str = ", ".join(f"{tbl.full_name}.{c.name}" for c in o_cols)

    condition_parts = []
    if rng.random() < 0.5 and prof.user_cols:
        _, ucol = rng.choice(prof.user_cols)
        condition_parts.append(f"assigned to them")
    if rng.random() < 0.3 and prof.status_cols:
        _, scol = rng.choice(prof.status_cols)
        sv = rng.choice(STATUS_VALUES)
        condition_parts.append(f"with {_col_readable(scol)} {sv}")

    cond = " ".join(condition_parts)
    if cond:
        nl = f"{role.capitalize()} can {verb} {tbl_read} records {cond}."
    else:
        nl = f"{role.capitalize()} can {verb} {tbl_read} records."

    s_vars = ["app.employee_id", "app.job_role"]

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: {', '.join(s_vars)}\nO: {o_str}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_v7a",
        "pattern": "rbac_standard",
    }


def gen_rbac_temporal(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_A level: role + time constraint, |O|=2-4 (target mean ~2.8)"""
    if not prof.time_cols:
        return None
    tbl = rng.choice(prof.schema.tables)
    if len(tbl.columns) < 3:
        return None
    cmd = rng.choice(["SELECT", "UPDATE", "INSERT"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl.full_name)

    time_cond, e_var = rng.choice(TIME_CONDITIONS)

    non_pk = [c for c in tbl.columns if not c.is_pk]
    if not non_pk or len(non_pk) < 2:
        return None
    n_o = rng.randint(2, min(4, len(non_pk)))
    o_cols = rng.sample(non_pk, n_o)
    o_str = ", ".join(f"{tbl.full_name}.{c.name}" for c in o_cols)

    nl = f"{role.capitalize()} can {verb} {tbl_read} records {time_cond}."

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: app.employee_id, app.job_role\nO: {o_str}\nE: {e_var}",
        "stage": "anchor",
        "source": "spider_auth_v7a",
        "pattern": "rbac_temporal",
    }


def gen_ownership_role(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_A level: ownership + role, |O|=2-5"""
    if not prof.user_cols:
        return None
    tbl_name, user_col = rng.choice(prof.user_cols)
    tbl = prof.schema.table_by_short(tbl_name.split(".")[-1])
    if tbl is None or len(tbl.columns) < 3:
        return None
    cmd = rng.choice(["SELECT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl_name)

    extra_cols = [c for c in tbl.columns if c.name != user_col and not c.is_pk]
    if not extra_cols:
        return None
    n_extra = rng.randint(1, min(3, len(extra_cols)))
    chosen = rng.sample(extra_cols, n_extra)

    o_parts = [f"{tbl.full_name}.{user_col}"]
    for c in chosen:
        o_parts.append(f"{tbl.full_name}.{c.name}")
    o_str = ", ".join(o_parts)

    status_clause = ""
    for c in chosen:
        if classify_column(c.name) & {"status"}:
            sv = rng.choice(STATUS_VALUES)
            status_clause = f" with {_col_readable(c.name)} {sv}"
            break

    nl = f"{role.capitalize()} can {verb} their own {tbl_read} records{status_clause}."

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: app.employee_id, app.job_role\nO: {o_str}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_v7a",
        "pattern": "ownership_role",
    }


def gen_cross_table_moderate(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_B level: cross-table join, |O|=4-7 (target mean ~4.8)"""
    if prof.n_tables < 2:
        return None
    tbls = rng.sample(prof.schema.tables, min(2, len(prof.schema.tables)))
    main_tbl = tbls[0]
    join_tbl = tbls[1]

    if len(main_tbl.columns) < 3 or len(join_tbl.columns) < 2:
        return None

    cmd = rng.choice(["SELECT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)

    main_read = _table_readable(main_tbl.full_name)
    join_read = _table_readable(join_tbl.full_name)

    main_cols = rng.sample(main_tbl.columns, min(rng.randint(2, 4), len(main_tbl.columns)))
    join_cols = rng.sample(join_tbl.columns, min(rng.randint(2, 3), len(join_tbl.columns)))

    o_parts = [f"{main_tbl.full_name}.{c.name}" for c in main_cols]
    o_parts += [f"{join_tbl.full_name}.{c.name}" for c in join_cols]
    o_str = ", ".join(o_parts)

    s_vars = ["app.employee_id", "app.job_role"]
    if rng.random() < 0.4:
        s_vars.append("app.tenant_id")

    has_env = rng.random() < 0.5
    e_str = rng.choice(["current_time", "current_date", "current_timestamp"]) if has_env else ""

    time_clause = ""
    if has_env:
        time_clause = " " + rng.choice(TIME_CONDITIONS)[0]

    nl = (f"{role.capitalize()} can {verb} {main_read} records "
          f"linked to {join_read}{time_clause}.")

    return {
        "question": nl,
        "gold_table": main_tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: {', '.join(s_vars)}\nO: {o_str}\nE: {e_str}",
        "stage": "anchor",
        "source": "spider_auth_v7b",
        "pattern": "cross_table_moderate",
    }


def gen_tenant_scoped(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_B level: multi-tenant isolation, |O|=3-6 (target mean ~4.8)"""
    tbl = rng.choice(prof.schema.tables)
    if len(tbl.columns) < 4:
        return None
    cmd = rng.choice(["SELECT", "INSERT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl.full_name)

    non_pk = [c for c in tbl.columns if not c.is_pk]
    if len(non_pk) < 3:
        return None
    n_o = rng.randint(3, min(6, len(non_pk)))
    o_chosen = rng.sample(non_pk, n_o)
    o_parts = [f"{tbl.full_name}.{c.name}" for c in o_chosen]
    o_str = ", ".join(o_parts)

    s_vars = ["app.employee_id", "app.job_role", "app.tenant_id"]

    nl_variants = [
        f"{role.capitalize()} can {verb} {tbl_read} records in their own tenant.",
        f"{role.capitalize()} can only {verb} {tbl_read} within the current tenant.",
        f"Tenant-scoped {role} can {verb} {tbl_read} records in their tenant only.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: {', '.join(s_vars)}\nO: {o_str}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_v7b",
        "pattern": "tenant_scoped",
    }


def gen_hierarchical_complex(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_D level: hierarchical/recursive, |O|=4-8"""
    if prof.n_tables < 3:
        return None
    tbls = rng.sample(prof.schema.tables, min(3, len(prof.schema.tables)))
    main_tbl = tbls[0]
    if len(main_tbl.columns) < 3:
        return None

    cmd = rng.choice(["SELECT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(["managers", "directors", "supervisors", "department heads"])
    main_read = _table_readable(main_tbl.full_name)

    o_parts = []
    for t in tbls:
        n_from_t = rng.randint(2, min(4, len(t.columns)))
        chosen = rng.sample(t.columns, n_from_t)
        for c in chosen:
            o_parts.append(f"{t.full_name}.{c.name}")
    target_n = rng.randint(5, min(8, len(o_parts)))
    if len(o_parts) > target_n:
        o_parts = rng.sample(o_parts, target_n)
    o_str = ", ".join(o_parts)

    s_vars = ["app.employee_id", "app.job_role", "app.tenant_id"]
    if rng.random() < 0.5:
        s_vars.append("app.department_id")

    
    e_str = rng.choice(["current_time", "current_date", "current_timestamp"])
    time_clause = " " + rng.choice(TIME_CONDITIONS)[0]

    nl_variants = [
        f"{role.capitalize()} can {verb} {main_read} for employees in departments "
        f"they manage and all descendant departments in the hierarchy{time_clause}.",
        f"{role.capitalize()} can {verb} {main_read} records in their recursive "
        f"organizational subtree{time_clause}.",
        f"{role.capitalize()} can {verb} {main_read} for their direct reports "
        f"and all recursive subordinates{time_clause}.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": main_tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: {', '.join(s_vars)}\nO: {o_str}\nE: {e_str}",
        "stage": "anchor",
        "source": "spider_auth_v7d",
        "pattern": "hierarchical_complex",
    }


def gen_contrastive_cross_tenant(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """ct level: cross-tenant with conditions, |O|=6-10"""
    if prof.n_tables < 2:
        return None
    tbls = rng.sample(prof.schema.tables, min(2, len(prof.schema.tables)))
    main_tbl = tbls[0]
    aux_tbl = tbls[1]

    if len(main_tbl.columns) < 3 or len(aux_tbl.columns) < 3:
        return None

    cmd = rng.choice(["SELECT", "UPDATE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    main_read = _table_readable(main_tbl.full_name)

    o_parts = []
    for c in aux_tbl.columns:
        o_parts.append(f"{aux_tbl.full_name}.{c.name}")
    main_extra = rng.sample(main_tbl.columns, min(4, len(main_tbl.columns)))
    for c in main_extra:
        o_parts.append(f"{main_tbl.full_name}.{c.name}")
    rng.shuffle(o_parts)
    target_n = rng.choices([7, 8, 9, 10], weights=[3, 3, 2, 2], k=1)[0]
    o_parts = o_parts[:min(target_n, len(o_parts))]
    if len(o_parts) < 6:
        return None
    o_str = ", ".join(o_parts)

    s_vars = ["app.employee_id", "app.job_role", "app.tenant_id", "app.user_id"]
    e_str = "current_timestamp"

    aux_read = _table_readable(aux_tbl.full_name)
    nl_variants = [
        f"{role.capitalize()} can {verb} {main_read} in their own tenant. "
        f"Cross-tenant {CRUD_OPS[cmd][0]}s require an active {aux_read} "
        f"record linking the user to the target tenant.",
        f"{role.capitalize()} can {verb} {main_read} in their own tenant. "
        f"{main_read.capitalize()} from another tenant requires an approved, "
        f"unexpired {aux_read} entry.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": main_tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: {', '.join(s_vars)}\nO: {o_str}\nE: {e_str}",
        "stage": "anchor",
        "source": "spider_auth_ct",
        "pattern": "contrastive_cross_tenant",
    }


def gen_abac_status(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_C level: attribute-based on status, |O|=1-4 (target mean ~1.9)"""
    if not prof.status_cols:
        return None
    tbl_name, status_col = rng.choice(prof.status_cols)
    tbl = prof.schema.table_by_short(tbl_name.split(".")[-1])
    if tbl is None or len(tbl.columns) < 3:
        return None

    cmd = rng.choice(["SELECT", "UPDATE", "DELETE"])
    verb = rng.choice(CRUD_OPS[cmd])
    role = rng.choice(ROLES)
    tbl_read = _table_readable(tbl_name)
    sv = rng.choice(STATUS_VALUES)

    o_parts = [f"{tbl.full_name}.{status_col}"]
    extra = [c for c in tbl.columns if c.name != status_col and not c.is_pk]
    if extra:
        n_extra = rng.randint(1, min(3, len(extra)))
        for c in rng.sample(extra, n_extra):
            o_parts.append(f"{tbl.full_name}.{c.name}")
    o_str = ", ".join(o_parts)

    nl = f"{role.capitalize()} can {verb} {tbl_read} records with {_col_readable(status_col)} {sv}."

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: app.employee_id, app.job_role\nO: {o_str}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_v7c",
        "pattern": "abac_status",
    }


def gen_mac_security_level(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """MAC pattern: security level, |O|=1-3 (target mean ~1.9)"""
    tbl = rng.choice(prof.schema.tables)
    if len(tbl.columns) < 3:
        return None
    tbl_read = _table_readable(tbl.full_name)
    level = rng.randint(2, 5)

    non_pk = [c for c in tbl.columns if not c.is_pk]
    if not non_pk:
        return None
    n_o = rng.randint(1, min(3, len(non_pk)))
    o_parts = [f"{tbl.full_name}.{c.name}" for c in rng.sample(non_pk, n_o)]
    o_str = ", ".join(o_parts)

    has_env = rng.random() < 0.5
    e_str = "current_time" if has_env else ""
    time_clause = " during business hours (09:00-18:00)" if has_env else ""

    nl_variants = [
        f"Security level {level} or higher users can access {tbl_read} records{time_clause}.",
        f"Only users with clearance level {level}+ can view {tbl_read}{time_clause}.",
        f"Access to {tbl_read} requires security classification level {level} or above{time_clause}.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": "SELECT",
        "target_text": f"S: app.user_id, app.security_level\nO: {o_str}\nE: {e_str}",
        "stage": "anchor",
        "source": "spider_auth_v7c",
        "pattern": "mac_security_level",
    }


def gen_rebac_relationship(
    prof: SchemaProfile, rng: random.Random
) -> Optional[Dict]:
    """v7_B level: relationship-based, |O|=3-6 (target mean ~4.8)"""
    if prof.n_tables < 2 or not prof.fk_cols:
        return None
    tbl_name, fk_col = rng.choice(prof.fk_cols)
    tbl = prof.schema.table_by_short(tbl_name.split(".")[-1])
    if tbl is None or len(tbl.columns) < 4:
        return None

    cmd = rng.choice(["SELECT", "UPDATE"])
    verb = rng.choice(CRUD_OPS[cmd])
    tbl_read = _table_readable(tbl_name)
    fk_read = _col_readable(fk_col)

    extra = [c for c in tbl.columns if c.name != fk_col]
    if len(extra) < 2:
        return None
    n_extra = rng.randint(2, min(5, len(extra)))
    chosen = rng.sample(extra, n_extra)

    o_parts = [f"{tbl.full_name}.{fk_col}"]
    for c in chosen:
        o_parts.append(f"{tbl.full_name}.{c.name}")
    o_str = ", ".join(o_parts)

    nl_variants = [
        f"Users can {verb} {tbl_read} records related to their {fk_read}.",
        f"A user can only {verb} {tbl_read} entries where the {fk_read} matches their association.",
        f"Access to {tbl_read} is restricted to records linked through {fk_read}.",
    ]
    nl = rng.choice(nl_variants)

    return {
        "question": nl,
        "gold_table": tbl.full_name,
        "gold_cmd": cmd,
        "target_text": f"S: app.user_id\nO: {o_str}\nE: ",
        "stage": "anchor",
        "source": "spider_auth_v7b",
        "pattern": "rebac_relationship",
    }


# ---------------------------------------------------------------------------
# Scope-stage generator (paired with each anchor)
# ---------------------------------------------------------------------------

def make_scope(anchor: Dict) -> Dict:
    return {
        "schema": "",  # filled later
        "question": anchor["question"],
        "gold_table": anchor["gold_table"],
        "gold_cmd": anchor["gold_cmd"],
        "target_text": f"TARGET_TABLE: {anchor['gold_table']}\nTARGET_CMD: {anchor['gold_cmd']}",
        "stage": "scope",
        "source": anchor["source"],
    }


# ---------------------------------------------------------------------------
# Target distribution matching
# ---------------------------------------------------------------------------

TARGET_DISTRIBUTION = {
    # Maps to single-pred AT slice: |O|~1.0, simple ownership/global

    "spider_auth_tpl": {
        "count": 800,
        "generators": [
            (gen_ownership_simple, 0.90),
            (gen_ownership_global, 0.10),
        ],
    },
    # Bulk-standard AT slice: |O|~1.9, common patterns
    "spider_auth_v7c": {
        "count": 1200,
        "generators": [
            (gen_abac_status, 0.5),
            (gen_mac_security_level, 0.5),
        ],
    },
    # Role-based AT slice: |O|~2.8, single-table standard RLS
    "spider_auth_v7a": {
        "count": 1500,
        "generators": [
            (gen_rbac_standard, 0.35),
            (gen_rbac_temporal, 0.30),
            (gen_ownership_role, 0.35),
        ],
    },
    # Cross-table AT slice: |O|~4.8, moderate complexity
    "spider_auth_v7b": {
        "count": 1500,
        "generators": [
            (gen_cross_table_moderate, 0.35),
            (gen_tenant_scoped, 0.30),
            (gen_rebac_relationship, 0.35),
        ],
    },
    # Hierarchical AT slice: |O|~6.2, recursive / multi-hop
   
    "spider_auth_v7d": {
        "count": 350,
        "generators": [
            (gen_hierarchical_complex, 1.0),
        ],
    },
    # Maps to cross-tenant AT slice: |O|~7.7, contrastive cross-tenant

    "spider_auth_ct": {
        "count": 350,
        "generators": [
            (gen_contrastive_cross_tenant, 1.0),
        ],
    },
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser(description="Build cascade Spider auth templates")
    p.add_argument("--spider-schemas", required=True,
                   help="JSONL file with Spider schemas")
    p.add_argument("--out", required=True,
                   help="Output JSONL path")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--scale", type=float, default=1.0,
                   help="Scale all target counts by this factor")
    p.add_argument("--dry-run", action="store_true",
                   help="Print stats only, don't write")
    args = p.parse_args()

    rng = random.Random(args.seed)

    # Load Spider schemas
    schemas: List[SchemaInfo] = []
    with open(args.spider_schemas) as f:
        for line in f:
            r = json.loads(line)
            schemas.append(parse_schema(r["schema"]))
    print(f"Loaded {len(schemas)} Spider schemas", file=sys.stderr)

    # Profile each schema
    profiles = [profile_schema(s) for s in schemas]
    good = [p for p in profiles if p.score >= 2]
    print(f"Schemas with score >= 2: {len(good)}/{len(profiles)}", file=sys.stderr)

    # Generate training examples
    all_examples: List[Dict] = []
    stats = {}

    for source_name, spec in TARGET_DISTRIBUTION.items():
        target = int(spec["count"] * args.scale)
        gens = spec["generators"]
        gen_funcs = [g for g, _ in gens]
        gen_weights = [w for _, w in gens]

        generated = []
        attempts = 0
        max_attempts = target * 20

        while len(generated) < target and attempts < max_attempts:
            attempts += 1
            prof = rng.choice(good)
            gen_fn = rng.choices(gen_funcs, weights=gen_weights, k=1)[0]
            result = gen_fn(prof, rng)
            if result is None:
                continue

            # Attach schema
            result["schema"] = prof.schema.raw
            generated.append(result)

        stats[source_name] = {
            "target": target,
            "generated": len(generated),
            "attempts": attempts,
        }
        all_examples.extend(generated)

    # Report stats
    print(f"\n{'Source':<25} {'Target':>7} {'Generated':>10} {'Attempts':>9}",
          file=sys.stderr)
    print("-" * 55, file=sys.stderr)
    total = 0
    for src, s in stats.items():
        print(f"{src:<25} {s['target']:>7} {s['generated']:>10} {s['attempts']:>9}",
              file=sys.stderr)
        total += s["generated"]
    print(f"{'TOTAL':<25} {'':>7} {total:>10}", file=sys.stderr)

    # Verify O-count distribution
    from collections import Counter
    o_dist_by_src: Dict[str, Counter] = {}
    for ex in all_examples:
        src = ex["source"]
        o_line = ""
        for line in ex["target_text"].split("\n"):
            if line.strip().startswith("O:"):
                o_line = line.strip()[2:].strip()
        n_o = len([x for x in o_line.split(",") if x.strip()]) if o_line else 0
        if src not in o_dist_by_src:
            o_dist_by_src[src] = Counter()
        o_dist_by_src[src][n_o] += 1

    print("\n|O| distribution by source:", file=sys.stderr)
    for src in sorted(o_dist_by_src):
        dist = o_dist_by_src[src]
        vals = []
        for ex in all_examples:
            if ex["source"] != src:
                continue
            o_line = ""
            for line in ex["target_text"].split("\n"):
                if line.strip().startswith("O:"):
                    o_line = line.strip()[2:].strip()
            n_o = len([x for x in o_line.split(",") if x.strip()]) if o_line else 0
            vals.append(n_o)
        if vals:
            mean_o = sum(vals) / len(vals)
            print(f"  {src}: mean|O|={mean_o:.1f}, range={min(vals)}-{max(vals)}, "
                  f"n={len(vals)}", file=sys.stderr)

    if args.dry_run:
        print("\nDry run — no file written.", file=sys.stderr)
        return

    # Write output: interleave scope + anchor pairs
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        for ex in all_examples:
            scope = make_scope(ex)
            scope["schema"] = ex["schema"]
            f.write(json.dumps(scope, ensure_ascii=False) + "\n")
            f.write(json.dumps(ex, ensure_ascii=False) + "\n")

    print(f"\nWrote {len(all_examples)} anchor examples "
          f"({len(all_examples) * 2} total lines) to {out_path}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
