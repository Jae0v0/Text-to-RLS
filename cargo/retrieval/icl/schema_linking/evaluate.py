"""Set-level metrics for table retrieval against gold table sets."""
from __future__ import annotations

from typing import Dict, List, Set


def _prf(pred: Set[str], gold: Set[str]) -> Dict[str, float]:
    if not pred and not gold:
        return {"precision": 1.0, "recall": 1.0, "f1": 1.0}
    tp = len(pred & gold)
    precision = tp / len(pred) if pred else 0.0
    recall = tp / len(gold) if gold else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0
    return {"precision": precision, "recall": recall, "f1": f1}


def evaluate(predictions: Dict[str, List[str]],
             gold: Dict[str, List[str]]) -> Dict:
    """predictions/gold keyed by policy id (str) -> list of schema.table.

    Returns aggregate metrics plus per-item detail. Macro-averaged over items.
    """
    per_item = []
    agg = {"precision": 0.0, "recall": 0.0, "f1": 0.0, "exact_match": 0.0,
           "full_coverage": 0.0}
    n = len(gold)
    for pid, g in gold.items():
        gset = set(g)
        pset = set(predictions.get(pid, []))
        m = _prf(pset, gset)
        exact = 1.0 if pset == gset else 0.0
        coverage = 1.0 if gset <= pset else 0.0  # all gold tables retrieved
        per_item.append({
            "id": pid, "gold": sorted(gset), "pred": sorted(pset),
            **m, "exact_match": exact, "full_coverage": coverage,
        })
        for key in ("precision", "recall", "f1"):
            agg[key] += m[key]
        agg["exact_match"] += exact
        agg["full_coverage"] += coverage

    if n:
        for key in agg:
            agg[key] /= n
    return {"n": n, "aggregate": agg, "per_item": per_item}
