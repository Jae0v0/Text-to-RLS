"""Build the PMI-based keyword map η from the training corpus.

For each anchor token a appearing in some gold (S, O, E) tuple, we:
  1. Collect NL tokens from the corresponding requirement N that co-occur
     with a within a ±5-token window (matched via anchor sub-tokens).
  2. Compute pointwise mutual information PMI(a, w) across all examples.
  3. Retain the top-10 NL tokens by PMI per anchor token.

The output JSON maps normalized anchor names to their top-k keyword lists:
  {"user_id": ["user", "account", "own", ...], ...}

Usage:
  python3 cargo/extractor/train/build_keyword_map.py \
    --train data/anchor_train_cascade.jsonl \
    --out   data/keyword_map_eta.json \
    --top-k 10 --window 5
"""
from __future__ import annotations

import argparse
import json
import math
import re
import string
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple

# ---------------------------------------------------------------------------
# Stopwords (minimal English set — no NLTK dependency)
# ---------------------------------------------------------------------------

STOPWORDS: Set[str] = {
    "a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "will", "would", "shall",
    "should", "may", "might", "must", "can", "could",
    "i", "me", "my", "we", "our", "you", "your", "he", "him", "his",
    "she", "her", "it", "its", "they", "them", "their",
    "this", "that", "these", "those", "which", "who", "whom", "what",
    "in", "on", "at", "to", "for", "of", "with", "by", "from", "as",
    "into", "through", "during", "before", "after", "above", "below",
    "between", "out", "off", "over", "under", "about", "up", "down",
    "and", "but", "or", "nor", "not", "no", "so", "if", "then", "than",
    "too", "very", "just", "also", "only", "each", "every", "all", "any",
    "both", "few", "more", "most", "other", "some", "such", "how", "when",
    "where", "why", "here", "there", "again", "once", "further",
    # domain-generic
    "data", "table", "column", "row", "record", "value", "field",
    "select", "insert", "update", "delete", "query", "database",
}


# ---------------------------------------------------------------------------
# Simple lemmatizer (suffix stripping, no NLTK)
# ---------------------------------------------------------------------------

# Conservative lemma: only well-known plurals and verb forms.
# Aggressive stemming produces unreadable fragments (e.g. "designat").
_PLURAL_RULES = [
    ("ies", "y"),    # policies → policy
    ("ves", "fe"),   # lives → life
    ("sses", "ss"),  # addresses → address
    ("ses", "se"),   # cases → case
    ("s", ""),       # users → user  (only if len > 4)
]


def _lemma(word: str) -> str:
    """Conservative suffix lemmatization — preserves readability."""
    if len(word) <= 3:
        return word
    # Only strip obvious plural 's'
    for suffix, repl in _PLURAL_RULES:
        if word.endswith(suffix):
            candidate = word[: -len(suffix)] + repl
            if len(candidate) >= 3:
                return candidate
    return word


# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------

_TOK_RE = re.compile(r"[a-z][a-z']+")


def _is_proper_noun_like(word: str) -> bool:
    """Heuristic: if the original token was capitalized and not sentence-start."""
    # We check against a set of common proper-noun patterns from Spider
    return len(word) > 3 and word[0].isupper() and not word.isupper()


def tokenize_nl(text: str) -> List[str]:
    """Lowercase, extract alpha tokens, remove stopwords, lemmatize.

    Also filters out likely proper nouns (capitalized mid-sentence words)
    to prevent noise from Spider-specific entity names.
    """
    # First pass: identify proper nouns (capitalized non-start words)
    raw_tokens = re.findall(r"[A-Za-z][a-z']+", text)
    proper_nouns: Set[str] = set()
    for i, tok in enumerate(raw_tokens):
        if i > 0 and _is_proper_noun_like(tok):
            proper_nouns.add(tok.lower())

    tokens = _TOK_RE.findall(text.lower())
    return [
        _lemma(t) for t in tokens
        if t not in STOPWORDS and len(t) > 2 and t not in proper_nouns
    ]


def normalize_anchor(raw: str) -> str:
    """Strip table/app prefix: 'employees.employee_id' → 'employee_id'."""
    parts = raw.strip().split(".")
    return parts[-1].lower() if parts else raw.lower()


def anchor_subtokens(anchor_norm: str) -> List[str]:
    """Split anchor name by underscore: 'employee_id' → ['employee']."""
    parts = [p for p in anchor_norm.split("_") if len(p) > 2 and p != "id"]
    return parts if parts else [anchor_norm]


# ---------------------------------------------------------------------------
# Core: extract co-occurrences with ±W window
# ---------------------------------------------------------------------------

def extract_anchors_from_target(target_text: str) -> List[str]:
    """Parse S/O/E lines from anchor target_text, return normalized tokens."""
    anchors: List[str] = []
    for line in target_text.split("\n"):
        line = line.strip()
        if line.startswith(("S:", "O:", "E:")):
            body = line.split(":", 1)[1]
            for tok in body.split(","):
                tok = tok.strip()
                if tok:
                    anchors.append(normalize_anchor(tok))
    return anchors


def windowed_cooccurrence(
    question_tokens: List[str],
    anchor_subtoks: List[str],
    window: int,
) -> Set[str]:
    """Find NL tokens within ±window of any anchor sub-token match."""
    hit_positions: List[int] = []
    for i, qt in enumerate(question_tokens):
        for st in anchor_subtoks:
            if st in qt or qt in st:
                hit_positions.append(i)
                break

    if not hit_positions:
        # No lexical overlap: skip this example for this anchor.
        # Returning all tokens would inflate co-occurrence for opaque names.
        return set()

    result: Set[str] = set()
    hit_set = set(hit_positions)
    for pos in hit_positions:
        lo = max(0, pos - window)
        hi = min(len(question_tokens), pos + window + 1)
        for j in range(lo, hi):
            result.add(question_tokens[j])
    return result


# ---------------------------------------------------------------------------
# PMI computation
# ---------------------------------------------------------------------------

def compute_pmi_map(
    train_path: str,
    window: int = 5,
    top_k: int = 10,
    min_count: int = 3,
) -> Dict[str, List[str]]:
    """Build keyword map η with PMI from training corpus."""

    # Pass 1: collect co-occurrence counts
    # anchor → {nl_token → count}
    cooccur: Dict[str, Counter] = defaultdict(Counter)
    anchor_count: Counter = Counter()       # how many examples each anchor appears in
    word_count: Counter = Counter()         # how many examples each NL token appears in
    n_examples = 0

    with open(train_path) as fh:
        for line in fh:
            r = json.loads(line)
            if r["stage"] != "anchor":
                continue
            n_examples += 1
            question = r["question"]
            q_tokens = tokenize_nl(question)
            if not q_tokens:
                continue

            q_token_set = set(q_tokens)
            word_count.update(q_token_set)

            anchors_raw = extract_anchors_from_target(r["target_text"])
            seen_anchors: Set[str] = set()

            for a_norm in anchors_raw:
                if a_norm in seen_anchors:
                    continue
                seen_anchors.add(a_norm)
                anchor_count[a_norm] += 1

                subtoks = anchor_subtokens(a_norm)
                window_tokens = windowed_cooccurrence(q_tokens, subtoks, window)
                cooccur[a_norm].update(window_tokens)

    print(f"Corpus: {n_examples} anchor examples", file=sys.stderr)
    print(f"Unique anchors: {len(anchor_count)}", file=sys.stderr)

    if n_examples == 0:
        print("WARNING: no anchor-stage examples found", file=sys.stderr)
        return {}

    # Pass 2: compute PMI, keep top-k per anchor
    n_total = n_examples  # denominator for P(a) and P(w)
    # Filter: skip words appearing in >40% of all examples (too generic)
    max_word_freq = 0.40 * n_total
    eta: Dict[str, List[str]] = {}

    for anchor, word_counts in cooccur.items():
        if anchor_count[anchor] < min_count:
            continue

        p_a = anchor_count[anchor] / n_total
        scored: List[Tuple[str, float]] = []

        for word, joint_count in word_counts.items():
            if joint_count < min_count:
                continue
            if word_count[word] > max_word_freq:
                continue  # too generic
            p_w = word_count[word] / n_total
            p_aw = joint_count / n_total
            pmi = math.log2(p_aw / (p_a * p_w + 1e-12))
            # Also require minimum conditional prob P(w|a) >= 0.05
            p_w_given_a = joint_count / anchor_count[anchor]
            if p_w_given_a < 0.05:
                continue
            scored.append((word, pmi))

        scored.sort(key=lambda x: -x[1])
        pmi_keywords = [w for w, _ in scored[:top_k]]

        # Seed with anchor sub-tokens (e.g., "user" for "user_id") that are
        # not already in the PMI list. These have trivial co-occurrence but
        # are the strongest lexical signals in practice.
        subtoks = anchor_subtokens(anchor)
        seed = [s for s in subtoks if s not in set(pmi_keywords)]
        keywords = seed + pmi_keywords  # sub-tokens first, then PMI
        keywords = keywords[:top_k]     # cap at top_k total

        if keywords:
            eta[anchor] = keywords

    print(f"|η| = {len(eta)} entries", file=sys.stderr)
    if eta:
        avg_kw = sum(len(v) for v in eta.values()) / len(eta)
        print(f"Average keywords per entry: {avg_kw:.1f}", file=sys.stderr)

    return eta


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser(description="Build PMI keyword map η")
    p.add_argument("--train", required=True,
                   help="Path to cascade training JSONL")
    p.add_argument("--out", required=True,
                   help="Output JSON path for keyword map")
    p.add_argument("--top-k", type=int, default=10,
                   help="Top-k keywords per anchor token (default: 10)")
    p.add_argument("--window", type=int, default=5,
                   help="±window size for co-occurrence (default: 5)")
    p.add_argument("--min-count", type=int, default=3,
                   help="Minimum co-occurrence count (default: 3)")
    args = p.parse_args()

    eta = compute_pmi_map(
        args.train,
        window=args.window,
        top_k=args.top_k,
        min_count=args.min_count,
    )

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as fh:
        json.dump(eta, fh, indent=2, ensure_ascii=False)

    print(f"\nSaved η to {out_path} ({len(eta)} entries)", file=sys.stderr)

    # Print sample entries
    print("\n--- Sample entries ---", file=sys.stderr)
    for anchor in sorted(eta.keys())[:15]:
        print(f"  {anchor}: {eta[anchor]}", file=sys.stderr)


if __name__ == "__main__":
    main()
