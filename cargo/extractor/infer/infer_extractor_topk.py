"""Top-K cascaded decoding of the extractor (paper §IV-C, Algorithm 1 lines 1-10).

Pass 1 (scope):  schema + question -> diverse beam search returns B_S scope
                 candidates with cumulative log-probability g_S and length L_S.
Pass 2 (anchor): for each scope candidate, schema + pred_scope + question ->
                 diverse beam search returns B_A anchor candidates (g_A, L_A).

The joint cascade score for hypothesis (b, h) is (Eq. 15):
    ell_{b,h} = (g_S^{(b)} + g_A^{(b,h)}) / (L_S^{(b)} + L_A^{(b,h)})

We retain the global top-K hypotheses across the B_S x B_A grid, ready for
the downstream schema-constrained reranker.

Output JSONL (one row per test item):
  {
    id, question,
    candidates: [
      {
        rank, scope_rank, anchor_rank,
        ell_joint, ell_scope, ell_anchor,
        pred_table, pred_cmd, pred_s, pred_o, pred_e,
        scope_raw, anchor_raw,
      },
      ...
    ],
    gold_table, gold_cmd, gold_s, gold_o, gold_e,
    oracle_hit_rank,                   # 1..K if any candidate matches gold SOEA, else None
    scope_ms, anchor_ms, gen_ms,
    difficulty, attribute_pattern,
  }

Usage:
  CUDA_VISIBLE_DEVICES=0 python3 cargo/extractor/infer/infer_extractor_topk.py \
    --adapter adapters/cascade_extractor/final \
    --test data/test_text2rls.jsonl \
    --out predictions/cascade_top3.jsonl \
    --beams-scope 3 --beams-anchor 3 --topk 3
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

# ---------------------------------------------------------------------------
# Prompt templates (must match train_codes3b_cascade.py)
# ---------------------------------------------------------------------------

SCOPE_PROMPT_TPL = "{schema}\n\nREQUEST: {question}\n\nSCOPE:\n"
ANCHOR_PROMPT_TPL = (
    "{schema}\n\n"
    "TARGET_TABLE: {table}\nTARGET_CMD: {cmd}\n\n"
    "REQUEST: {question}\n\n"
    "ANCHOR:\n"
)

# ---------------------------------------------------------------------------
# Tag parsers (same as infer_codes3b_cascade.py)
# ---------------------------------------------------------------------------

_SCOPE_RE = {
    "table": re.compile(r"TARGET_TABLE:[ \t]*([^\n]+)", re.I),
    "cmd":   re.compile(r"TARGET_CMD:[ \t]*([^\n]+)", re.I),
}
_ANCHOR_RE = {
    "s": re.compile(r"^S:[ \t]*([^\n]*)", re.I | re.M),
    "o": re.compile(r"^O:[ \t]*([^\n]*)", re.I | re.M),
    "e": re.compile(r"^E:[ \t]*([^\n]*)", re.I | re.M),
}


def parse_scope(text: str) -> Dict[str, str]:
    out: Dict[str, str] = {"table": "", "cmd": ""}
    for k, regex in _SCOPE_RE.items():
        m = regex.search(text)
        if m:
            out[k] = m.group(1).strip()
    return out


def parse_anchor(text: str) -> Dict[str, List[str]]:
    out: Dict[str, List[str]] = {"s": [], "o": [], "e": []}
    for k, regex in _ANCHOR_RE.items():
        m = regex.search(text)
        if not m:
            continue
        val = m.group(1).strip()
        out[k] = [x.strip() for x in val.split(",") if x.strip()] if val else []
    return out


def gold_from_item(r: Dict) -> Dict[str, object]:
    return {
        "table": r.get("gold_table") or r.get("target_table"),
        "cmd": (r.get("action") or r.get("target_cmd") or "SELECT").upper(),
        "s": sorted(set(
            a.lower() for a in (r.get("gold_subject_accessors")
                                or r.get("s_attributes") or [])
        )),
        "o": sorted(set(r.get("gold_columns") or r.get("o_attributes") or [])),
        "e": sorted(set(
            e.lower() for e in (r.get("gold_environment_accessors")
                                or r.get("e_attributes") or [])
        )),
    }


# ---------------------------------------------------------------------------
# Beam-search generator
# ---------------------------------------------------------------------------

def sequence_logprob(
    model: torch.nn.Module, prompt_ids: torch.Tensor, gen_tokens: torch.Tensor,
    pad_id: int, eos_id: int,
) -> Tuple[float, int, torch.Tensor]:
    """Exact log P(generated tokens | prompt), up to and including the first EOS.

    Beam scores from diverse beam search include the diversity penalty, so the
    cascade score g is recomputed from the model's log-probabilities.
    """
    toks = gen_tokens.tolist()
    if eos_id in toks:
        toks = toks[: toks.index(eos_id) + 1]
    toks = [t for t in toks if t != pad_id or t == eos_id] or [eos_id]
    gen = torch.tensor([toks], device=prompt_ids.device)
    full = torch.cat([prompt_ids, gen], dim=1)
    with torch.no_grad():
        logits = model(input_ids=full).logits[0, prompt_ids.shape[1] - 1:-1].float()
    logp = torch.log_softmax(logits, dim=-1).gather(1, gen[0].unsqueeze(1)).sum()
    return float(logp), len(toks), gen[0]


def generate_beam(
    model: torch.nn.Module,
    tok: AutoTokenizer,
    prompt: str,
    num_beams: int,
    num_return: int,
    max_new: int,
    max_len: int,
    device: str,
    num_beam_groups: int = 1,
    diversity_penalty: float = 0.0,
) -> Tuple[List[str], List[float], List[int], float]:
    """(Diverse) beam search over a single prompt.

    Returns (decoded_texts, cumulative_log_probs g, generated_lengths L, elapsed_ms).

    With num_beam_groups > 1 and diversity_penalty > 0 this is Diverse Beam
    Search (Vijayakumar et al.). Raw g and L are returned so the caller can
    compute the joint length normalisation of Eq. 15:
        ell_joint = (g_S + g_A) / (L_S + L_A)
    """
    enc = tok(
        prompt, return_tensors="pt",
        truncation=True, max_length=max_len,
    ).to(device)
    prompt_len = enc.input_ids.shape[1]

    gen_kwargs = dict(
        max_new_tokens=max_new,
        num_beams=num_beams,
        num_return_sequences=num_return,
        do_sample=False,
        length_penalty=1.0,
        return_dict_in_generate=True,
        pad_token_id=tok.pad_token_id,
    )
    if num_beam_groups > 1 and diversity_penalty > 0:
        gen_kwargs["num_beam_groups"] = num_beam_groups
        gen_kwargs["diversity_penalty"] = diversity_penalty
        gen_kwargs["trust_remote_code"] = True

    t0 = time.perf_counter()
    with torch.no_grad():
        gen_out = model.generate(**enc, **gen_kwargs)

    decoded: List[str] = []
    lengths: List[int] = []
    cum_logprobs: List[float] = []
    for j in range(num_return):
        g, L, toks = sequence_logprob(
            model, enc.input_ids, gen_out.sequences[j][prompt_len:],
            tok.pad_token_id, tok.eos_token_id,
        )
        decoded.append(tok.decode(toks, skip_special_tokens=True))
        lengths.append(L)
        cum_logprobs.append(g)
    elapsed_ms = (time.perf_counter() - t0) * 1000
    return decoded, cum_logprobs, lengths, elapsed_ms


def generate_o_constrained(
    model: torch.nn.Module,
    tok: AutoTokenizer,
    prompt: str,
    num_candidates: int,
    max_new: int,
    max_len: int,
    device: str,
) -> Tuple[List[str], List[float], List[int], float]:
    """O-constrained sequential decoding for anchor diversity.

    Generates candidates one at a time (greedy). After each generation,
    extracts O column names and adds their token sequences to bad_words_ids,
    forcing the next generation to produce different O columns.

    Returns (decoded_texts, cumulative_log_probs, generated_lengths, elapsed_ms).
    """
    enc = tok(
        prompt, return_tensors="pt",
        truncation=True, max_length=max_len,
    ).to(device)
    prompt_len = enc.input_ids.shape[1]

    t0 = time.perf_counter()
    decoded: List[str] = []
    lengths: List[int] = []
    cum_logprobs: List[float] = []
    banned_seqs: List[List[int]] = []  # token sequences to ban
    pad_id = tok.pad_token_id

    for _ in range(num_candidates):
        gen_kwargs = dict(
            max_new_tokens=max_new,
            num_beams=1,
            do_sample=False,
            pad_token_id=tok.pad_token_id,
            return_dict_in_generate=True,
            output_scores=True,
        )
        if banned_seqs:
            gen_kwargs["bad_words_ids"] = banned_seqs

        with torch.no_grad():
            gen_out = model.generate(**enc, **gen_kwargs)

        gen_tokens = gen_out.sequences[0][prompt_len:]
        L = int((gen_tokens != pad_id).sum().item())
        L = max(L, 1)
        text = tok.decode(gen_tokens, skip_special_tokens=True)

        # Compute sequence log-prob from per-step scores
        scores = gen_out.scores  # tuple of (vocab_size,) tensors
        g = 0.0
        for step_idx in range(min(L, len(scores))):
            logp = torch.log_softmax(scores[step_idx][0], dim=-1)
            token_id = gen_tokens[step_idx].item()
            if token_id != pad_id:
                g += logp[token_id].item()

        decoded.append(text)
        lengths.append(L)
        cum_logprobs.append(g)

        # Extract O columns and ban their token sequences
        o_match = re.search(r"^O:[ \t]*([^\n]*)", text, re.I | re.M)
        if o_match:
            o_str = o_match.group(1).strip()
            o_cols = [c.strip() for c in o_str.split(",") if c.strip()]
            for col in o_cols:
                col_ids = tok.encode(col, add_special_tokens=False)
                if col_ids and col_ids not in banned_seqs:
                    banned_seqs.append(col_ids)

    elapsed_ms = (time.perf_counter() - t0) * 1000
    return decoded, cum_logprobs, lengths, elapsed_ms


def generate_sample(
    model: torch.nn.Module,
    tok: AutoTokenizer,
    prompt: str,
    num_samples: int,
    max_new: int,
    max_len: int,
    device: str,
    temperature: float = 0.8,
    top_p: float = 0.95,
) -> Tuple[List[str], List[float], List[int], float]:
    """Temperature sampling for diversity (low memory, one sequence at a time).

    Returns (decoded_texts, cumulative_log_probs, generated_lengths, elapsed_ms).
    Log-probs are approximated as 0.0 since sampling doesn't produce proper
    beam-style scores — caller should use a uniform score for ranking.
    """
    enc = tok(
        prompt, return_tensors="pt",
        truncation=True, max_length=max_len,
    ).to(device)
    prompt_len = enc.input_ids.shape[1]

    t0 = time.perf_counter()
    decoded: List[str] = []
    lengths: List[int] = []
    cum_logprobs: List[float] = []
    pad_id = tok.pad_token_id
    for _ in range(num_samples):
        with torch.no_grad():
            gen_out = model.generate(
                **enc,
                max_new_tokens=max_new,
                do_sample=True,
                temperature=temperature,
                top_p=top_p,
                num_return_sequences=1,
                pad_token_id=tok.pad_token_id,
            )
        gen_tokens = gen_out[0][prompt_len:]
        L = int((gen_tokens != pad_id).sum().item())
        L = max(L, 1)
        decoded.append(tok.decode(gen_tokens, skip_special_tokens=True))
        lengths.append(L)
        cum_logprobs.append(0.0)  # no meaningful score from sampling

    elapsed_ms = (time.perf_counter() - t0) * 1000
    return decoded, cum_logprobs, lengths, elapsed_ms


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--test", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--base", default="seeklhy/codes-3b")
    p.add_argument("--adapter", required=True)
    p.add_argument("--max-new", type=int, default=200)
    p.add_argument("--max-len", type=int, default=8192,
                   help="prompt token budget (CodeS context); longer prompts are "
                        "truncated from the left so the request is kept")
    p.add_argument("--beams-scope", type=int, default=3,
                   help="B_S: beam width and num_return for Stage-1 scope")
    p.add_argument("--beams-anchor", type=int, default=3,
                   help="B_A: beam width and num_return for Stage-2 anchor")
    p.add_argument("--topk", type=int, default=3,
                   help="K: number of joint hypotheses retained "
                        "(must satisfy K <= B_S * B_A)")
    p.add_argument("--dbs-groups", type=int, default=3,
                   help="num_beam_groups of diverse beam search in both stages "
                        "(must divide B_S and B_A; 1 = standard beam search)")
    p.add_argument("--dbs-penalty", type=float, default=0.5,
                   help="diversity_penalty of diverse beam search (0 = off)")
    p.add_argument("--anchor-o-constrain", action="store_true",
                   help="Use O-constrained sequential decoding for anchor "
                        "(ban previously-seen O columns each round)")
    p.add_argument("--anchor-sample", action="store_true",
                   help="Use temperature sampling for anchor stage "
                        "(low memory, high diversity)")
    p.add_argument("--anchor-temperature", type=float, default=0.8,
                   help="Temperature for anchor sampling (default 0.8)")
    p.add_argument("--anchor-top-p", type=float, default=0.95,
                   help="Top-p for anchor sampling (default 0.95)")
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--device", default="cuda")
    args = p.parse_args()

    B_S = args.beams_scope
    B_A = args.beams_anchor
    K = args.topk

    if args.dbs_groups > 1:
        assert B_S % args.dbs_groups == 0 and B_A % args.dbs_groups == 0, (
            f"B_S={B_S} and B_A={B_A} must be divisible by dbs_groups="
            f"{args.dbs_groups}"
        )
    assert K <= B_S * B_A, (
        f"topk K={K} exceeds B_S*B_A={B_S*B_A}; reduce K or raise beams"
    )

    print(f"=== loading base {args.base} ===", file=sys.stderr)
    tok = AutoTokenizer.from_pretrained(args.base, trust_remote_code=True)
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token
    tok.truncation_side = "left"
    base = AutoModelForCausalLM.from_pretrained(
        args.base, trust_remote_code=True,
        torch_dtype=torch.bfloat16,
        device_map={"": args.device},
    )
    print(f"=== loading LoRA adapter {args.adapter} ===", file=sys.stderr)
    model = PeftModel.from_pretrained(base, args.adapter)
    model.eval()

    with open(args.test) as fh:
        items = [json.loads(line) for line in fh]
    if args.limit:
        items = items[: args.limit]
    dbs_str = ""
    if args.anchor_o_constrain:
        dbs_str = " anchor-O-CONSTRAIN(ban prev O cols)"
    elif args.anchor_sample:
        dbs_str = (f" anchor-SAMPLE(T={args.anchor_temperature}, "
                   f"top_p={args.anchor_top_p})")
    elif args.dbs_groups > 1:
        dbs_str = (f" DBS(groups={args.dbs_groups}, "
                   f"penalty={args.dbs_penalty})")
    print(
        f"=== cascade top-K inference: B_S={B_S} B_A={B_A} K={K}"
        f"{dbs_str} over {len(items)} items ===",
        file=sys.stderr,
    )

    out_p = Path(args.out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    t_start = time.perf_counter()

    # Running metrics
    n = 0
    top1_soea_ok = 0
    oracle_soea_ok = 0    # any of top-K matches gold SOEA

    with out_p.open("w") as f:
        for i, item in enumerate(items):
            # --- Pass 1: scope beam (returns B_S candidates) ---
            scope_prompt = SCOPE_PROMPT_TPL.format(
                schema=item["schema"], question=item["question"],
            )
            scope_decoded, scope_gs, scope_Ls, scope_ms = generate_beam(
                model, tok, scope_prompt,
                num_beams=B_S, num_return=B_S,
                max_new=args.max_new, max_len=args.max_len, device=args.device,
                num_beam_groups=args.dbs_groups,
                diversity_penalty=args.dbs_penalty,
            )
            # Parse each scope candidate
            scopes = [parse_scope(s) for s in scope_decoded]

            # --- Pass 2: anchor beam (per scope candidate, returns B_A each) ---
            torch.cuda.empty_cache()  # free scope KV cache before anchor
            anchor_ms_total = 0.0
            joint_candidates: List[Dict] = []
            for b, (sc, g_S, L_S) in enumerate(zip(scopes, scope_gs, scope_Ls)):
                pred_table = sc["table"] or "UNKNOWN"
                pred_cmd = sc["cmd"].upper() if sc["cmd"] else "SELECT"
                anchor_prompt = ANCHOR_PROMPT_TPL.format(
                    schema=item["schema"], question=item["question"],
                    table=pred_table, cmd=pred_cmd,
                )
                if args.anchor_o_constrain:
                    anchor_decoded, anchor_gs, anchor_Ls, am = \
                        generate_o_constrained(
                            model, tok, anchor_prompt,
                            num_candidates=B_A,
                            max_new=args.max_new, max_len=args.max_len,
                            device=args.device,
                        )
                elif args.anchor_sample:
                    anchor_decoded, anchor_gs, anchor_Ls, am = generate_sample(
                        model, tok, anchor_prompt,
                        num_samples=B_A,
                        max_new=args.max_new, max_len=args.max_len,
                        device=args.device,
                        temperature=args.anchor_temperature,
                        top_p=args.anchor_top_p,
                    )
                else:
                    anchor_decoded, anchor_gs, anchor_Ls, am = generate_beam(
                        model, tok, anchor_prompt,
                        num_beams=B_A, num_return=B_A,
                        max_new=args.max_new, max_len=args.max_len,
                        device=args.device,
                        num_beam_groups=args.dbs_groups,
                        diversity_penalty=args.dbs_penalty,
                    )
                anchor_ms_total += am

                for h, (a_raw, g_A, L_A) in enumerate(
                    zip(anchor_decoded, anchor_gs, anchor_Ls)
                ):
                    a = parse_anchor(a_raw)
                    # Joint length-normalised score: ell = (g_S + g_A) / (L_S + L_A)
                    ell_joint = (g_S + g_A) / max(1, L_S + L_A)
                    joint_candidates.append({
                        "scope_rank": b,
                        "anchor_rank": h,
                        "g_scope": round(g_S, 4),
                        "g_anchor": round(g_A, 4),
                        "L_scope": L_S,
                        "L_anchor": L_A,
                        "ell_joint": round(ell_joint, 4),
                        "pred_table": sc["table"] or None,
                        "pred_cmd": (sc["cmd"].upper() if sc["cmd"] else None),
                        "pred_s": [s.lower() for s in a["s"]],
                        "pred_o": a["o"],
                        "pred_e": [e.lower() for e in a["e"]],
                        "scope_raw": scope_decoded[b][:200],
                        "anchor_raw": a_raw[:200],
                    })

            # --- Global top-K ---
            joint_candidates.sort(key=lambda c: -c["ell_joint"])
            topk_cands = joint_candidates[:K]
            for rank, c in enumerate(topk_cands, 1):
                c["rank"] = rank

            # --- Evaluate against gold ---
            gold = gold_from_item(item)

            def _soea_match(c: Dict) -> bool:
                return (
                    (c["pred_table"] or "").lower() == (gold["table"] or "").lower()
                    and (c["pred_cmd"] or "") == (gold["cmd"] or "")
                    and set(c["pred_s"]) == set(gold["s"])
                    and set(c["pred_o"]) == set(gold["o"])
                    and set(c["pred_e"]) == set(gold["e"])
                )

            oracle_hit_rank = None
            for c in topk_cands:
                if _soea_match(c):
                    oracle_hit_rank = c["rank"]
                    break

            gen_ms = scope_ms + anchor_ms_total
            row = {
                "id": item.get("id") or item.get("orig_id"),
                "question": item.get("question", "")[:300],
                "candidates": topk_cands,
                "gold_table": gold["table"],
                "gold_cmd": gold["cmd"],
                "gold_s": gold["s"],
                "gold_o": gold["o"],
                "gold_e": gold["e"],
                "oracle_hit_rank": oracle_hit_rank,
                "scope_ms": round(scope_ms, 1),
                "anchor_ms": round(anchor_ms_total, 1),
                "gen_ms": round(gen_ms, 1),
                "difficulty": item.get("difficulty"),
                "attribute_pattern": item.get("attribute_pattern"),
            }
            f.write(json.dumps(row) + "\n")

            # Running metrics
            n += 1
            if topk_cands and _soea_match(topk_cands[0]):
                top1_soea_ok += 1
            if oracle_hit_rank is not None:
                oracle_soea_ok += 1

            if (i + 1) % 20 == 0 or i == len(items) - 1:
                tot = time.perf_counter() - t_start
                eta = tot / (i + 1) * (len(items) - i - 1)
                print(
                    f"  [{i+1:3d}/{len(items)}] "
                    f"top1-SOEA={top1_soea_ok/n:.3f} "
                    f"oracle@{K}-SOEA={oracle_soea_ok/n:.3f} "
                    f"el={tot:.0f}s eta={eta:.0f}s",
                    file=sys.stderr,
                )

    elapsed_min = (time.perf_counter() - t_start) / 60
    print(f"\n=== DONE in {elapsed_min:.1f} min ===", file=sys.stderr)
    print(f"=== FINAL (n={n}, B_S={B_S}, B_A={B_A}, K={K}) ===", file=sys.stderr)
    print(
        f"  top-1 SOEA item-perfect: {top1_soea_ok}/{n} "
        f"= {100*top1_soea_ok/n:.1f}%",
        file=sys.stderr,
    )
    print(
        f"  oracle@{K} SOEA item-perfect: {oracle_soea_ok}/{n} "
        f"= {100*oracle_soea_ok/n:.1f}%",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
