"""LLM table retriever.

Two interchangeable backends:
  * vllm     -- fast, but needs vllm/transformers compatibility.
  * transformers -- plain HF generate; no special runtime, single GPU.

On this server vllm 0.6.6 is incompatible with the installed transformers 5.x,
so the transformers backend is the default.
"""
from __future__ import annotations

import logging
import re
from typing import List, Set

logger = logging.getLogger(__name__)

_TABLE_RE = re.compile(r"[A-Za-z_][\w]*\.[A-Za-z_][\w]*")


def parse_tables(text: str, known: Set[str]) -> List[str]:
    """Extract valid schema.table names from a generated line, in order, deduped.

    Only the first generated line is considered (the model continues the
    'Tables:' line, then we stop at the newline).
    """
    first_line = text.split("\n", 1)[0]
    out: List[str] = []
    for tok in _TABLE_RE.findall(first_line):
        if tok in known and tok not in out:
            out.append(tok)
    return out


class HFRetriever:
    """Plain transformers backend: batched greedy completion."""

    def __init__(self, model_path: str, known_tables: Set[str],
                 batch_size: int = 8, max_new_tokens: int = 64):
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer
        self.torch = torch
        self.known = known_tables
        self.batch_size = batch_size
        self.max_new_tokens = max_new_tokens
        self.tok = AutoTokenizer.from_pretrained(model_path)
        if self.tok.pad_token is None:
            self.tok.pad_token = self.tok.eos_token
        self.tok.padding_side = "left"
        self.model = AutoModelForCausalLM.from_pretrained(
            model_path, dtype=torch.bfloat16, device_map="cuda")
        self.model.eval()

    def predict(self, prompts: List[str]) -> List[List[str]]:
        preds: List[List[str]] = []
        for i in range(0, len(prompts), self.batch_size):
            batch = prompts[i:i + self.batch_size]
            enc = self.tok(batch, return_tensors="pt", padding=True,
                           truncation=True, max_length=16384).to(self.model.device)
            with self.torch.no_grad():
                out = self.model.generate(
                    **enc, max_new_tokens=self.max_new_tokens,
                    do_sample=False, pad_token_id=self.tok.pad_token_id)
            gen = out[:, enc["input_ids"].shape[1]:]
            texts = self.tok.batch_decode(gen, skip_special_tokens=True)
            preds.extend(parse_tables(t, self.known) for t in texts)
            logger.info("  generated %d/%d", min(i + self.batch_size, len(prompts)),
                        len(prompts))
        return preds


class LLMRetriever:
    """Wrap a vllm engine to turn prompts into predicted table lists."""

    def __init__(self, model_path: str, known_tables: Set[str],
                 max_model_len: int = 16384, gpu_memory_utilization: float = 0.85):
        from vllm import LLM, SamplingParams
        self.known = known_tables
        self.llm = LLM(
            model=model_path,
            max_model_len=max_model_len,
            gpu_memory_utilization=gpu_memory_utilization,
            tensor_parallel_size=1,
        )
        # Base model: stop as soon as the single "Tables:" line ends.
        self.sampling = SamplingParams(
            temperature=0.0,
            max_tokens=128,
            stop=["\n", "Description:"],
        )

    def predict(self, prompts: List[str]) -> List[List[str]]:
        outputs = self.llm.generate(prompts, self.sampling)
        # vllm may reorder; each output carries its prompt, so realign by prompt.
        by_prompt = {o.prompt: o for o in outputs}
        preds: List[List[str]] = []
        for p in prompts:
            text = by_prompt[p].outputs[0].text
            preds.append(parse_tables(text, self.known))
        return preds
