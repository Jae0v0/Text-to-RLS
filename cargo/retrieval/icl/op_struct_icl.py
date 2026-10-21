"""Operation-routed demonstration retrieval (paper §IV-D, Eqs. 18-21, Algorithm 2).

Pool K: demonstrations d = (N_d, T_d, O_d, A_d, P_d) with gold scope and anchors.
  1. Routing (Eq. 18):  K_O = {d in K | O_d = O*}.
  2. Relevance (Eq. 19): r(d) = alpha_s * 1[T* = T_d] + alpha_a * ovlp(A*, A_d),
     where ovlp is the Jaccard overlap over runtime, row and environment anchors.
  3. Selection (Eq. 21): for m = 1..k,
        d_m = argmax_{d in K_O \\ R} [ r(d) + xi * min_{d' in R} delta_A(d, d') ],
     with delta_A(d, d') = 1 - ovlp(A_d, A_d') and min over an empty R = 0.
     Nearest-selection distances are cached, so each step is O(|K_O| * a).
  4. Fallback: once K_O \\ R is empty, selection continues from
     K \\ (R u {d | N_d = N}) under the same rule.
Leave-one-out: d with N_d = N is never selected.
"""
from __future__ import annotations

import ast
import re
from dataclasses import dataclass
from typing import Dict, FrozenSet, Iterable, List, Optional, Sequence, Tuple

ALPHA_S = 0.3
ALPHA_A = 0.7
XI = 0.3
K_DEMOS = 5

# Clock accessors written in different forms denote the same environment anchor.
_ENV_ALIASES = {
    "app_now()": "current_timestamp",
    "now()": "current_timestamp",
    "app_now()::timestamp": "current_timestamp",
    "app_now()::date": "current_date",
    "app_now()::time": "current_time",
    "localtimestamp": "current_timestamp",
    "localtime": "current_time",
}

Anchor = Tuple[str, str]          # (channel, name), channel in {run, row, env}


@dataclass(frozen=True)
class Demo:
    id: str
    question: str
    sql: str
    table: str
    op: str
    run: Tuple[str, ...]
    row: Tuple[str, ...]
    env: Tuple[str, ...]

    @property
    def anchors(self) -> FrozenSet[Anchor]:
        return anchor_set(self.run, self.row, self.env)


def as_list(value) -> List[str]:
    """Attribute lists are stored either as lists or as their string repr."""
    if value is None:
        return []
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return []
        try:
            value = ast.literal_eval(value)
        except (ValueError, SyntaxError):
            value = [v for v in value.strip("[]").split(",")]
    return [str(v).strip().strip("'\"") for v in value if str(v).strip().strip("'\"")]


def _norm(channel: str, name: str) -> str:
    name = name.strip().strip('"').lower()
    if channel == "env":
        name = _ENV_ALIASES.get(name, name)
    return name


def anchor_set(run: Iterable[str], row: Iterable[str], env: Iterable[str]) -> FrozenSet[Anchor]:
    return frozenset(
        [("run", _norm("run", a)) for a in run]
        + [("row", _norm("row", a)) for a in row]
        + [("env", _norm("env", a)) for a in env]
    )


def ovlp(a: FrozenSet[Anchor], b: FrozenSet[Anchor]) -> float:
    """Jaccard overlap of two typed anchor sets (0 when both are empty)."""
    union = a | b
    return len(a & b) / len(union) if union else 0.0


def policy_scope(sql: str) -> Tuple[str, str]:
    """(target table, command) of a CREATE POLICY statement; no FOR clause means ALL.

    The policy name is skipped first, since quoted names (e.g. Supabase examples)
    may contain the words "on" or "for".
    """
    m = re.search(r'\bCREATE\s+POLICY\s+(?:"[^"]*"|\S+)\s+ON\s+([\w."]+)', sql, re.I)
    table = m.group(1).replace('"', "")
    cmd = re.search(r"\bFOR\s+(ALL|SELECT|INSERT|UPDATE|DELETE)\b", sql[m.end():], re.I)
    return table.lower(), (cmd.group(1).upper() if cmd else "ALL")


def _same_requirement(a: str, b: str) -> bool:
    return " ".join(a.lower().split()) == " ".join(b.lower().split())


def relevance(t_star: str, a_star: FrozenSet[Anchor], d: Demo,
              alpha_s: float = ALPHA_S, alpha_a: float = ALPHA_A) -> float:
    """r(d) = 1 - delta_q(d) (Eq. 19)."""
    return alpha_s * float(t_star.lower() == d.table) + alpha_a * ovlp(a_star, d.anchors)


def select_demos(
    question: str,
    t_star: str,
    o_star: str,
    a_star: FrozenSet[Anchor],
    pool: Sequence[Demo],
    k: int = K_DEMOS,
    xi: float = XI,
    alpha_s: float = ALPHA_S,
    alpha_a: float = ALPHA_A,
) -> List[Demo]:
    """Greedy nearest-redundancy selection of k demonstrations (Eq. 21)."""
    eligible = [d for d in pool if not _same_requirement(d.question, question)]
    routed = [d for d in eligible if d.op == o_star.upper()]

    rel: Dict[str, float] = {}
    nearest: Dict[str, float] = {}       # min_{d' in R} delta_A(d, d')
    selected: List[Demo] = []
    chosen: set = set()

    def score(d: Demo) -> float:
        if d.id not in rel:
            rel[d.id] = relevance(t_star, a_star, d, alpha_s, alpha_a)
        return rel[d.id] + xi * nearest.get(d.id, 0.0)

    for _ in range(k):
        candidates = [d for d in routed if d.id not in chosen]
        if not candidates:                                   # fallback (Alg. 2, line 9)
            candidates = [d for d in eligible if d.id not in chosen]
        if not candidates:
            break
        best: Optional[Demo] = None
        best_score = -1.0
        for d in candidates:
            s = score(d)
            if s > best_score:
                best, best_score = d, s
        selected.append(best)
        chosen.add(best.id)
        for d in eligible:
            dist = 1.0 - ovlp(d.anchors, best.anchors)
            nearest[d.id] = dist if len(selected) == 1 else min(nearest[d.id], dist)
    return selected
