"""StructICL: SOEA-Guided Structural ICL Demonstration Selection.

Replaces fixed op-anchor × TF-IDF with a multi-dimensional relevance
score + MMR diversity selection.

Score(q, d) = α·Sim_NL + β·Sim_SOEA + γ·Sim_op + δ·Sim_pattern
              + η·Sim_schema + μ·Reliability(d)

Selection: greedy MMR with redundancy penalty.
"""
from __future__ import annotations

import re
import logging
from typing import Any, Dict, List, Optional, Set, Tuple

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Similarity functions
# ---------------------------------------------------------------------------

def _jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0
    return len(a & b) / max(1, len(a | b))


def sim_soea(q_soea: Dict, d_soea: Dict) -> float:
    """SOEA attribute-set Jaccard similarity."""
    q_all = set(q_soea.get("pred_s", [])) | set(q_soea.get("pred_o", [])) | set(q_soea.get("pred_e", []))
    d_all = set(d_soea.get("pred_s", [])) | set(d_soea.get("pred_o", [])) | set(d_soea.get("pred_e", []))
    return _jaccard(q_all, d_all)


def sim_op(q_cmd: str, d_cmd: str) -> float:
    """Operation match: 1.0 if same, 0.3 if related, 0.0 otherwise."""
    if q_cmd == d_cmd:
        return 1.0
    # UPDATE and ALL are related (both need USING + WITH CHECK)
    related = {
        ("UPDATE", "ALL"), ("ALL", "UPDATE"),
        ("SELECT", "DELETE"),  ("DELETE", "SELECT"),  # both USING-only
    }
    if (q_cmd, d_cmd) in related:
        return 0.3
    return 0.0


def sim_pattern(q_pattern: str, d_pattern: str) -> float:
    """Attribute pattern similarity."""
    if q_pattern == d_pattern:
        return 1.0
    # Compatible patterns
    COMPAT = {
        "temporal": {"combined": 0.4, "compliance_invariant": 0.3},
        "nested": {"hierarchy_recursive": 0.5, "combined": 0.3},
        "hierarchy_recursive": {"nested": 0.5},
        "compliance_invariant": {"combined": 0.4, "relational": 0.3},
        "ordinal": {"relational": 0.3, "combined": 0.3},
        "relational": {"compliance_invariant": 0.3, "ordinal": 0.3},
        "combined": {},
    }
    return COMPAT.get(q_pattern, {}).get(d_pattern, 0.0)


def sim_schema(q_soea: Dict, d_soea: Dict, q_table: str, d_table: str) -> float:
    """Schema/relation-path similarity based on target table and cross-table refs."""
    score = 0.0
    # Same target table schema (e.g. both hr.*)
    if q_table and d_table:
        q_schema = q_table.split(".")[0] if "." in q_table else ""
        d_schema = d_table.split(".")[0] if "." in d_table else ""
        if q_table == d_table:
            score += 0.5
        elif q_schema == d_schema:
            score += 0.3

    # Cross-table reference similarity (O attributes from other tables)
    q_cross = set()
    d_cross = set()
    for o in q_soea.get("pred_o", []):
        tbl = ".".join(o.split(".")[:-1])
        if tbl and tbl != q_table:
            q_cross.add(tbl)
    for o in d_soea.get("pred_o", []):
        tbl = ".".join(o.split(".")[:-1])
        if tbl and tbl != d_table:
            d_cross.add(tbl)
    score += 0.5 * _jaccard(q_cross, d_cross)
    return score


def demo_reliability(d_soea: Dict, d_gold_sql: str) -> float:
    """How well does the extractor prediction match the demo's gold SQL?
    Higher = extractor hint is consistent with gold → safer demo."""
    if not d_gold_sql:
        return 0.0
    sql_upper = d_gold_sql.upper()

    checks = 0
    matches = 0

    # Check pred_table
    pred_table = d_soea.get("pred_table", "")
    if pred_table:
        checks += 1
        if pred_table.upper() in sql_upper:
            matches += 1

    # Check pred_cmd
    pred_cmd = d_soea.get("pred_cmd", "")
    if pred_cmd:
        checks += 1
        if f"FOR {pred_cmd.upper()}" in sql_upper:
            matches += 1

    # Check pred_s: are predicted session vars actually in SQL?
    for sv in d_soea.get("pred_s", []):
        checks += 1
        if sv in d_gold_sql:
            matches += 1

    # Check pred_o: are predicted object columns in SQL?
    for o in d_soea.get("pred_o", []):
        col = o.split(".")[-1]
        checks += 1
        if col in d_gold_sql:
            matches += 1

    return matches / max(1, checks)


# ---------------------------------------------------------------------------
# Composite relevance
# ---------------------------------------------------------------------------

DEFAULT_WEIGHTS = {
    "alpha": 0.20,   # NL similarity
    "beta":  0.25,   # SOEA similarity
    "gamma": 0.15,   # operation similarity
    "delta": 0.15,   # pattern similarity
    "eta":   0.15,   # schema/relation similarity
    "mu":    0.10,   # demo reliability
}


def relevance(
    q_item: Dict,
    d_item: Dict,
    q_soea: Dict,
    d_soea: Dict,
    nl_sim: float,
    weights: Dict = None,
) -> float:
    """Composite relevance score R(q, d)."""
    w = weights or DEFAULT_WEIGHTS
    q_cmd = q_soea.get("pred_cmd", "SELECT")
    d_cmd = d_soea.get("pred_cmd", "SELECT")
    q_pattern = q_item.get("attribute_pattern", "")
    d_pattern = d_item.get("attribute_pattern", "")
    q_table = q_soea.get("pred_table", "")
    d_table = d_soea.get("pred_table", "")

    score = (
        w["alpha"] * nl_sim
        + w["beta"] * sim_soea(q_soea, d_soea)
        + w["gamma"] * sim_op(q_cmd, d_cmd)
        + w["delta"] * sim_pattern(q_pattern, d_pattern)
        + w["eta"] * sim_schema(q_soea, d_soea, q_table, d_table)
        + w["mu"] * demo_reliability(d_soea, d_item.get("sql", ""))
    )
    return score


# ---------------------------------------------------------------------------
# MMR selection
# ---------------------------------------------------------------------------

def select_demos_mmr(
    test_item: Dict,
    test_soea: Dict,
    demo_pool: List[Dict],
    demo_soeas: Dict[int, Dict],
    tfidf_matrix,
    tfidf_id_to_row: Dict[int, int],
    k: int = 5,
    lam_diversity: float = 0.3,
    min_reliability: float = 0.4,
    weights: Dict = None,
) -> List[int]:
    """Select k demos via greedy MMR with multi-dimensional relevance.

    Args:
        test_item: {id, question, attribute_pattern, sql, ...}
        test_soea: {pred_table, pred_cmd, pred_s, pred_o, pred_e}
        demo_pool: list of all demo items (gold policies)
        demo_soeas: {id: soea_dict} for each demo
        tfidf_matrix: precomputed TF-IDF matrix
        tfidf_id_to_row: {item_id: row_index}
        k: number of demos to select
        lam_diversity: redundancy penalty weight (0=no diversity, 1=max diversity)
        min_reliability: minimum demo reliability threshold
        weights: relevance weight dict

    Returns:
        List of selected demo IDs (ordered)
    """
    test_id = test_item["id"]
    test_row = tfidf_id_to_row.get(test_id)

    # Pre-filter: exclude test item + low-reliability demos
    candidates = []
    for d in demo_pool:
        did = d["id"]
        if did == test_id:
            continue
        d_soea = demo_soeas.get(did, {})
        rel = demo_reliability(d_soea, d.get("sql", ""))
        if rel < min_reliability:
            continue
        candidates.append(d)

    if not candidates:
        candidates = [d for d in demo_pool if d["id"] != test_id]

    # Precompute NL similarities
    nl_sims = {}
    if test_row is not None:
        for d in candidates:
            d_row = tfidf_id_to_row.get(d["id"])
            if d_row is not None:
                nl_sims[d["id"]] = cosine_similarity(
                    tfidf_matrix[test_row], tfidf_matrix[d_row]
                )[0, 0]
            else:
                nl_sims[d["id"]] = 0.0

    # Precompute full relevance scores
    rel_scores = {}
    for d in candidates:
        did = d["id"]
        d_soea = demo_soeas.get(did, {})
        nl = nl_sims.get(did, 0.0)
        rel_scores[did] = relevance(test_item, d, test_soea, d_soea, nl, weights)

    # Greedy MMR with cross-op guarantee
    selected = []
    selected_set = set()
    test_cmd = (test_soea.get("pred_cmd") or "SELECT").upper()

    import re as _re
    def _gold_op(sql):
        m = _re.search(r"FOR\s+(SELECT|INSERT|UPDATE|DELETE|ALL)\b", sql.upper())
        return m.group(1) if m else "SELECT"

    for _ in range(min(k, len(candidates))):
        best_id = None
        best_mmr = -float("inf")

        # On the last slot: if all selected so far are same-op,
        # force pick from a DIFFERENT op (cross-op diversity guarantee)
        force_cross_op = False
        if len(selected) == k - 1 and selected:
            selected_ops = {_gold_op(next((d for d in candidates if d["id"] == s), {"sql": ""}).get("sql", "")) for s in selected}
            if len(selected_ops) == 1:
                force_cross_op = True

        for d in candidates:
            did = d["id"]
            if did in selected_set:
                continue

            if force_cross_op:
                d_op = _gold_op(d.get("sql", ""))
                if d_op == test_cmd:
                    continue  # skip same-op on forced cross-op slot

            r = rel_scores[did]

            # Redundancy: max similarity to already selected
            if selected:
                max_red = max(
                    sim_soea(demo_soeas.get(did, {}), demo_soeas.get(s, {}))
                    for s in selected
                )
            else:
                max_red = 0.0

            mmr = r - lam_diversity * max_red

            if mmr > best_mmr:
                best_mmr = mmr
                best_id = did

        if best_id is not None:
            selected.append(best_id)
            selected_set.add(best_id)

    return selected
