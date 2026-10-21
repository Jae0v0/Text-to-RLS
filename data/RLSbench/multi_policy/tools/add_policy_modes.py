"""Add PERMISSIVE/RESTRICTIVE structure to the multi-policy bundles without changing behavior.

Input : multi.json (multi_v2, 60 bundles / 151 policies, no explicit policy modes)
Output: multi_v3.json (same bundles; behavior-equivalent reference policies)

Rules
-----
R1  Tenant isolation becomes one RESTRICTIVE policy.
    When ``tenant_id = current_setting('app.tenant_id', true)::int`` is ANDed into
    *every* clause that PostgreSQL enforces for *every* policy in the bundle
    (SELECT/DELETE: USING; INSERT: WITH CHECK; UPDATE/ALL: USING and WITH CHECK,
    where a missing WITH CHECK defaults to USING), it is moved out of the
    permissive policies together with its guard
    ``current_setting('app.tenant_id', true) IS NOT NULL`` (when that guard is
    equally shared). All other session guards stay in the permissive policies.
    The moved conjuncts R form ``CREATE POLICY ... AS RESTRICTIVE FOR ALL USING (R)
    WITH CHECK (R)``; the remaining policies are marked ``AS PERMISSIVE``.
    Equivalence: PostgreSQL enforces (P1 OR ... OR Pn) AND R. Because every Pi
    originally contained R, OR_i (Pi' AND R) = (OR_i Pi') AND R in three-valued
    logic, so every command and clause admits exactly the same rows.

R2  A top-level disjunctive conjunct in a SELECT/DELETE USING clause, X AND (A OR B),
    is split into two PERMISSIVE policies X AND A and X AND B on the same command.
    PostgreSQL ORs permissive policies of one command, so behavior is unchanged.

Every rewritten bundle is re-parsed and checked clause by clause against the
original (``verify``); the script aborts on any mismatch.

Requires: pglast (PostgreSQL parser).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from pglast import parse_sql
from pglast.enums import BoolExprType
from pglast.stream import RawStream

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "multi.json"
DST = ROOT / "multi_v3.json"

TENANT_CANON = "tenant_id = CAST(current_setting('app.tenant_id', TRUE) AS integer)"


# ---------------------------------------------------------------- AST helpers
def canon(node) -> str:
    return RawStream()(node)


def canon_text(expr: str) -> str:
    return canon(parse_sql(f"SELECT {expr}")[0].stmt.targetList[0].val)


def conjuncts(node) -> list:
    if node is None:
        return []
    if type(node).__name__ == "BoolExpr" and node.boolop == BoolExprType.AND_EXPR:
        out = []
        for arg in node.args:
            out += conjuncts(arg)
        return out
    return [node]


def enforced(stmt) -> dict:
    cmd = stmt.cmd_name.lower()
    if cmd in ("select", "delete"):
        return {(cmd, "USING"): stmt.qual}
    if cmd == "insert":
        return {(cmd, "WITH CHECK"): stmt.with_check}
    wc = stmt.with_check if stmt.with_check is not None else stmt.qual
    return {(cmd, "USING"): stmt.qual, (cmd, "WITH CHECK"): wc}


TENANT_GUARD_CANON = "current_setting('app.tenant_id', TRUE) IS NOT NULL"
TENANT_INVARIANT = {TENANT_GUARD_CANON, TENANT_CANON}


# ---------------------------------------------------------------- text helpers
def split_statements(sql: str) -> list[str]:
    return [s.strip().rstrip(";").strip() for s in re.split(r";\s*(?=CREATE\s+POLICY)", sql, flags=re.I) if s.strip()]


def scan_top_level(text: str):
    """Yield (index, char, depth, in_quote) for each character."""
    depth, quote = 0, False
    for i, ch in enumerate(text):
        if ch == "'":
            quote = not quote
        elif not quote and ch == "(":
            depth += 1
        elif not quote and ch == ")":
            depth -= 1
        yield i, ch, depth, quote


def clause_span(stmt: str, keyword: str):
    """Return (open_paren_index, close_paren_index) of USING(...) or WITH CHECK(...) at depth 0."""
    pat = re.compile(r"\bUSING\s*\(" if keyword == "USING" else r"\bWITH\s+CHECK\s*\(", re.I)
    depth, quote = 0, False
    for i, ch in enumerate(stmt):
        if ch == "'":
            quote = not quote
        if quote:
            continue
        if depth == 0:
            m = pat.match(stmt, i)
            if m and (i == 0 or not stmt[i - 1].isalnum()):
                open_idx = m.end() - 1
                d = 0
                for j in range(open_idx, len(stmt)):
                    if stmt[j] == "'":
                        quote = not quote
                    if quote:
                        continue
                    d += stmt[j] == "("
                    d -= stmt[j] == ")"
                    if d == 0:
                        return open_idx, j
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
    return None


def split_and(text: str) -> list[str]:
    """Split on top-level AND, keeping BETWEEN x AND y together."""
    parts, start, between, depth, quote = [], 0, 0, 0, False
    up = text.upper()
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            quote = not quote
        elif not quote and ch == "(":
            depth += 1
        elif not quote and ch == ")":
            depth -= 1
        elif not quote and depth == 0:
            if re.match(r"\bBETWEEN\b", up[i:]) and (i == 0 or not up[i - 1].isalnum()):
                between += 1
            m = re.match(r"\s+AND\s+", text[i:], re.I)
            if m and i > 0:
                if between:
                    between -= 1
                else:
                    parts.append(text[start:i].strip())
                    start = i + m.end()
                i += m.end()
                continue
        i += 1
    parts.append(text[start:].strip())
    return [p for p in parts if p]


def strip_outer(p: str) -> str | None:
    """Return inner text if p is fully wrapped in one pair of parentheses."""
    if not (p.startswith("(") and p.endswith(")")):
        return None
    for i, ch, depth, quote in scan_top_level(p):
        if depth == 0 and i < len(p) - 1:
            return None
    return p[1:-1].strip()


def remove_conjuncts(expr: str, drop: set[str]) -> tuple[str, dict[str, str]]:
    """Remove conjuncts whose canonical form is in drop; return new text and removed originals."""
    kept, removed = [], {}
    for piece in split_and(expr):
        c = canon_text(piece)
        if c in drop:
            removed.setdefault(c, piece)
            continue
        inner = strip_outer(piece)
        if inner is not None and len(split_and(inner)) > 1 and canon_text(inner).count(" AND ") >= 1:
            sub, sub_removed = remove_conjuncts(inner, drop)
            removed.update({k: v for k, v in sub_removed.items() if k not in removed})
            if sub:
                kept.append(f"({sub})" if len(split_and(sub)) > 1 else sub)
            continue
        kept.append(piece)
    return " AND ".join(kept), removed


# ---------------------------------------------------------------- rules
def rule_restrictive(bundle: dict) -> list[str] | None:
    stmts_txt = split_statements(bundle["sql"])
    stmts_ast = [parse_sql(s)[0].stmt for s in stmts_txt]
    clause_sets = [
        {canon(c) for c in conjuncts(e)}
        for st in stmts_ast
        for e in enforced(st).values()
    ]
    common = set.intersection(*clause_sets)
    if TENANT_CANON not in common:
        return None
    drop = TENANT_INVARIANT & common

    table = stmts_ast[0].table.relname
    schema = stmts_ast[0].table.schemaname
    originals: dict[str, str] = {}
    new_stmts = []
    for txt, st in zip(stmts_txt, stmts_ast):
        for kw in ("WITH CHECK", "USING"):
            span = clause_span(txt, kw)
            if span is None:
                continue
            a, b = span
            new_expr, rem = remove_conjuncts(txt[a + 1 : b], drop)
            for k, v in rem.items():
                originals.setdefault(k, v)
            if not new_expr:
                new_expr = "true"
            txt = txt[: a + 1] + new_expr + txt[b:]
        txt = re.sub(r"(\bON\s+[\w.]+)\s+FOR\b", r"\1 AS PERMISSIVE FOR", txt, count=1, flags=re.I)
        new_stmts.append(txt)

    order = sorted(drop, key=lambda c: (c == TENANT_CANON, c))
    r_text = " AND ".join(originals[c] for c in order)
    name = f"{table}_{bundle['id']}_tenant_isolation"
    restrictive = (
        f"CREATE POLICY {name} ON {schema}.{table} AS RESTRICTIVE FOR ALL "
        f"USING ({r_text}) WITH CHECK ({r_text})"
    )
    return [restrictive] + new_stmts


def rule_split_or(stmts_txt: list[str]) -> list[str]:
    out = []
    for txt in stmts_txt:
        st = parse_sql(txt)[0].stmt
        if st.cmd_name.lower() not in ("select", "delete") or st.qual is None:
            out.append(txt)
            continue
        span = clause_span(txt, "USING")
        a, b = span
        pieces = split_and(txt[a + 1 : b])
        or_idx = [i for i, p in enumerate(pieces)
                  if (inner := strip_outer(p)) is not None
                  and type(parse_sql(f"SELECT {inner}")[0].stmt.targetList[0].val).__name__ == "BoolExpr"
                  and parse_sql(f"SELECT {inner}")[0].stmt.targetList[0].val.boolop == BoolExprType.OR_EXPR]
        if len(or_idx) != 1:
            out.append(txt)
            continue
        k = or_idx[0]
        node = parse_sql(f"SELECT {strip_outer(pieces[k])}")[0].stmt.targetList[0].val
        if len(node.args) != 2:
            out.append(txt)
            continue
        inner = strip_outer(pieces[k])
        branches = split_or(inner)
        name = re.match(r"CREATE\s+POLICY\s+(\S+)", txt, re.I).group(1)
        for suffix, br in zip(("a", "b"), branches):
            new_pieces = pieces[:k] + [br] + pieces[k + 1 :]
            new_txt = txt[: a + 1] + " AND ".join(new_pieces) + txt[b:]
            new_txt = new_txt.replace(f"CREATE POLICY {name}", f"CREATE POLICY {name}_{suffix}", 1)
            out.append(new_txt)
    return out


def split_or(text: str) -> list[str]:
    parts, start, depth, quote, i = [], 0, 0, False, 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            quote = not quote
        elif not quote and ch == "(":
            depth += 1
        elif not quote and ch == ")":
            depth -= 1
        elif not quote and depth == 0:
            m = re.match(r"\s+OR\s+", text[i:], re.I)
            if m:
                parts.append(text[start:i].strip())
                start = i + m.end()
                i += m.end()
                continue
        i += 1
    parts.append(text[start:].strip())
    return parts


# ---------------------------------------------------------------- verification
def dnf(expr) -> set:
    """Conjunct sets of expr, expanding one top-level OR conjunct (rule R2)."""
    cs = conjuncts(expr)
    ors = [c for c in cs if type(c).__name__ == "BoolExpr" and c.boolop == BoolExprType.OR_EXPR]
    base = frozenset(canon(c) for c in cs if c not in ors) - {"true", "TRUE"}
    if len(ors) != 1:
        return {frozenset(canon(c) for c in cs) - {"true", "TRUE"}}
    return {base | frozenset(canon(x) for x in conjuncts(branch)) for branch in ors[0].args}


def semantics(sql: str) -> dict:
    """Map (command, clause) -> (sorted restrictive conjuncts, sorted set of permissive conjunct-sets)."""
    perm, restr = {}, {}
    for txt in split_statements(sql):
        st = parse_sql(txt)[0].stmt
        cmds = ["select", "insert", "update", "delete"] if st.cmd_name.lower() == "all" else [st.cmd_name.lower()]
        for cmd in cmds:
            pseudo = type("S", (), {"cmd_name": cmd, "qual": st.qual, "with_check": st.with_check})
            for key, e in enforced(pseudo).items():
                if st.permissive:
                    perm.setdefault(key, set()).update(dnf(e))
                else:
                    restr.setdefault(key, set()).update(canon(c) for c in conjuncts(e))
    return perm, restr


def verify(old_sql: str, new_sql: str) -> None:
    old_perm, old_restr = semantics(old_sql)
    new_perm, new_restr = semantics(new_sql)
    assert not old_restr
    # Effective rule per (command, clause): OR over permissive sets, each ANDed with restrictive set.
    for key, old_sets in old_perm.items():
        r = new_restr.get(key, set())
        new_sets = {frozenset(s | r) for s in new_perm.get(key, set())}
        assert new_sets == old_sets, f"{key}: {old_sets} != {new_sets}"
    assert set(new_perm) == set(old_perm), "permissive command coverage changed"


def main() -> int:
    bundles = json.loads(SRC.read_text())
    n_restr = n_split = 0
    for b in bundles:
        old = b["sql"]
        stmts = rule_restrictive(b)
        if stmts is not None:
            n_restr += 1
        else:
            stmts = split_statements(old)
        split = rule_split_or(stmts)
        if len(split) != len(stmts):
            n_split += 1
        if split == split_statements(old):
            continue  # no rule applied: keep the original text byte for byte
        b["sql"] = "\n".join(s + ";" for s in split)
        try:
            verify(old, b["sql"])
        except AssertionError as e:
            print(f"bundle {b['id']}: verification failed: {e}", file=sys.stderr)
            return 1
    DST.write_text(json.dumps(bundles, indent=2, ensure_ascii=False) + "\n")
    n_pol = sum(len(split_statements(b["sql"])) for b in bundles)
    print(f"bundles with a RESTRICTIVE policy: {n_restr}/60; bundles with an OR split: {n_split}; policies: {n_pol}")
    print(f"[saved] {DST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
