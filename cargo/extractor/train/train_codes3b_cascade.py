"""LoRA fine-tuning of CodeS-3B as the two-stage cascade extractor f_theta (paper §IV-C).

Stage S (scope):  schema + requirement -> TARGET_TABLE + TARGET_CMD
Stage A (anchor): schema + gold scope + requirement -> S (runtime) + O (row) + E (env)

One LoRA adapter is shared by both stages; the stages use different prompts.
Each stage minimizes the token-level NLL of its target (Eqs. 12-13), and the
stages are combined as L = lambda * L_s + (1 - lambda) * L_a (Eq. 14).

Prompt templates:
  Stage S:  {schema}\n\nREQUEST: {question}\n\nSCOPE:\n
  Stage A:  {schema}\n\nTARGET_TABLE: {t}\nTARGET_CMD: {c}\n\nREQUEST: {q}\n\nANCHOR:\n

Usage (a single run; 2 epochs, AdamW, lr 2e-4 as in the paper):
  CUDA_VISIBLE_DEVICES=0,1 python3 cargo/extractor/train/train_codes3b_cascade.py \
    --train data/cascade_train.jsonl --val data/cascade_dev.jsonl \
    --out adapters/cascade_extractor
"""
from __future__ import annotations

import argparse
import json
import math
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List

import torch
from torch.utils.data import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    Trainer,
    TrainingArguments,
)
from peft import LoraConfig, get_peft_model, TaskType

# ---------------------------------------------------------------------------
# Prompt templates — task discriminator via SCOPE: / ANCHOR: markers
# ---------------------------------------------------------------------------

SCOPE_PROMPT_TPL = "{schema}\n\nREQUEST: {question}\n\nSCOPE:\n"
ANCHOR_PROMPT_TPL = (
    "{schema}\n\n"
    "TARGET_TABLE: {table}\nTARGET_CMD: {cmd}\n\n"
    "REQUEST: {question}\n\n"
    "ANCHOR:\n"
)


# ---------------------------------------------------------------------------
# Dataset
# ---------------------------------------------------------------------------

@dataclass
class CascadeExample:
    prompt: str
    target: str
    stage: str          # "scope" or "anchor"


def load_cascade_jsonl(path: str) -> List[CascadeExample]:
    """Load the cascade supervision corpus. Each row carries a `stage` field (scope|anchor)."""
    out: List[CascadeExample] = []
    with open(path) as fh:
        for line in fh:
            r = json.loads(line)
            stage = r["stage"]
            if stage == "scope":
                prompt = SCOPE_PROMPT_TPL.format(
                    schema=r["schema"], question=r["question"],
                )
            else:
                prompt = ANCHOR_PROMPT_TPL.format(
                    schema=r["schema"], question=r["question"],
                    table=r["gold_table"], cmd=r["gold_cmd"],
                )
            out.append(CascadeExample(
                prompt=prompt, target=r["target_text"], stage=stage,
            ))
    return out


class CascadeDataset(Dataset):
    """Tokenizes prompt+target; `is_scope` marks which loss term a row feeds."""

    def __init__(
        self,
        examples: List[CascadeExample],
        tokenizer: Any,
        max_len: int = 4096,
    ):
        self.ex = examples
        self.tok = tokenizer
        self.max_len = max_len

    def __len__(self) -> int:
        return len(self.ex)

    def __getitem__(self, i: int) -> Dict[str, Any]:
        e = self.ex[i]
        prompt_ids = self.tok(e.prompt, add_special_tokens=False).input_ids
        target_ids = self.tok(e.target, add_special_tokens=False).input_ids
        target_ids = target_ids + [self.tok.eos_token_id]

        # Truncation budget
        budget = self.max_len
        max_t = max(64, int(budget * 0.20))
        max_p = budget - max_t - 1
        if len(prompt_ids) > max_p:
            head = int(max_p * 0.80)
            tail = max_p - head
            prompt_ids = prompt_ids[:head] + prompt_ids[-tail:]
        if len(target_ids) > max_t:
            target_ids = target_ids[: max_t - 1] + [self.tok.eos_token_id]

        input_ids = prompt_ids + target_ids
        return {
            "input_ids": input_ids,
            "attention_mask": [1] * len(input_ids),
            "labels": [-100] * len(prompt_ids) + target_ids,
            "is_scope": 1 if e.stage == "scope" else 0,
        }


# ---------------------------------------------------------------------------
# Pad collator
# ---------------------------------------------------------------------------

class CascadePadCollator:
    def __init__(self, tok: Any, pad_to_multiple: int = 8):
        self.tok = tok
        self.pad = pad_to_multiple

    def __call__(self, batch: List[Dict]) -> Dict[str, torch.Tensor]:
        m = max(len(b["input_ids"]) for b in batch)
        if self.pad > 1:
            m = ((m + self.pad - 1) // self.pad) * self.pad
        pad_id = self.tok.pad_token_id

        out: Dict[str, list] = {"input_ids": [], "attention_mask": [], "labels": []}
        for b in batch:
            n = len(b["input_ids"])
            out["input_ids"].append(b["input_ids"] + [pad_id] * (m - n))
            out["attention_mask"].append(b["attention_mask"] + [0] * (m - n))
            out["labels"].append(b["labels"] + [-100] * (m - n))

        return {
            "input_ids": torch.tensor(out["input_ids"], dtype=torch.long),
            "attention_mask": torch.tensor(out["attention_mask"], dtype=torch.long),
            "labels": torch.tensor(out["labels"], dtype=torch.long),
            "is_scope": torch.tensor([b["is_scope"] for b in batch], dtype=torch.bool),
        }


# ---------------------------------------------------------------------------
# Cascade objective (Eqs. 12-14)
# ---------------------------------------------------------------------------

def cascade_loss(
    logits: torch.Tensor, labels: torch.Tensor, is_scope: torch.Tensor, lam: float,
) -> torch.Tensor:
    """lambda * (summed scope-token NLL) + (1 - lambda) * (summed anchor-token NLL)."""
    shift_logits = logits[..., :-1, :].contiguous()
    shift_labels = labels[..., 1:].contiguous()
    B, T, V = shift_logits.shape
    per_token = torch.nn.functional.cross_entropy(
        shift_logits.view(B * T, V).float(), shift_labels.view(B * T),
        reduction="none", ignore_index=-100,
    ).view(B, T)
    per_row = per_token.sum(dim=1)                       # NLL over each target sequence
    loss_s = per_row[is_scope].sum()
    loss_a = per_row[~is_scope].sum()
    return lam * loss_s + (1.0 - lam) * loss_a


class CascadeTrainer(Trainer):
    """Trainer whose loss is the stage-weighted cascade objective."""

    def __init__(self, *args: Any, lam: float = 0.4, **kwargs: Any):
        super().__init__(*args, **kwargs)
        self.lam = lam

    def compute_loss(
        self,
        model: Any,
        inputs: Dict[str, torch.Tensor],
        return_outputs: bool = False,
        **kwargs: Any,
    ) -> Any:
        is_scope = inputs.pop("is_scope")
        labels = inputs.pop("labels")
        outputs = model(**inputs)
        loss = cascade_loss(outputs.logits, labels, is_scope, self.lam)
        return (loss, outputs) if return_outputs else loss


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--train", required=True)
    p.add_argument("--val", default=None)
    p.add_argument("--out", required=True, help="dir for LoRA adapter + ckpts")
    p.add_argument("--model", default="seeklhy/codes-3b")
    p.add_argument("--max-len", type=int, default=4096)
    p.add_argument("--epochs", type=int, default=2)
    p.add_argument("--lr", type=float, default=2e-4)
    p.add_argument("--lam", type=float, default=0.4,
                   help="stage weight lambda in L = lambda*L_s + (1-lambda)*L_a")
    p.add_argument("--batch", type=int, default=1)
    p.add_argument("--grad-accum", type=int, default=16)
    p.add_argument("--warmup-ratio", type=float, default=0.05)
    p.add_argument("--lora-r", type=int, default=16)
    p.add_argument("--lora-alpha", type=int, default=32)
    p.add_argument("--lora-dropout", type=float, default=0.05)
    p.add_argument("--save-steps", type=int, default=500)
    p.add_argument("--logging-steps", type=int, default=10)
    p.add_argument("--smoke-steps", type=int, default=0,
                   help="cap max_steps for a fast smoke run")
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--resume-adapter", default=None,
                   help="path to prior LoRA adapter to continue from")
    args = p.parse_args()

    print(f"=== cascade objective: lambda={args.lam} ===", file=sys.stderr, flush=True)

    # ---- Model ----
    print(f"=== loading {args.model} ===", file=sys.stderr, flush=True)
    tok = AutoTokenizer.from_pretrained(args.model, trust_remote_code=True)
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        args.model, trust_remote_code=True,
        torch_dtype=torch.bfloat16,
        device_map={"": "cuda"},
    )
    model.gradient_checkpointing_enable()
    if hasattr(model.config, "use_cache"):
        model.config.use_cache = False

    # ---- LoRA ----
    if args.resume_adapter:
        from peft import PeftModel
        print(f"=== resuming from adapter {args.resume_adapter} ===",
              file=sys.stderr)
        model = PeftModel.from_pretrained(
            model, args.resume_adapter, is_trainable=True,
        )
    else:
        sample_names = {n for n, _ in model.named_modules()}
        if any(".c_attn" in n for n in sample_names):
            target_modules = ["c_attn", "c_proj"]
        else:
            target_modules = ["q_proj", "k_proj", "v_proj", "o_proj"]
        print(f"=== LoRA target_modules: {target_modules} ===",
              file=sys.stderr)
        lora_cfg = LoraConfig(
            task_type=TaskType.CAUSAL_LM,
            r=args.lora_r, lora_alpha=args.lora_alpha,
            lora_dropout=args.lora_dropout,
            target_modules=target_modules,
            bias="none",
        )
        model = get_peft_model(model, lora_cfg)
    model.print_trainable_parameters()

    # ---- Data ----
    print("=== loading data ===", file=sys.stderr)
    train_ex = load_cascade_jsonl(args.train)
    val_ex = load_cascade_jsonl(args.val) if args.val else None
    n_scope = sum(1 for e in train_ex if e.stage == "scope")
    n_anchor = len(train_ex) - n_scope
    print(f"  train={len(train_ex)} (scope={n_scope}, anchor={n_anchor})"
          f" val={len(val_ex) if val_ex else 0}", file=sys.stderr)

    train_ds = CascadeDataset(train_ex, tok, max_len=args.max_len)
    val_ds = (CascadeDataset(val_ex, tok, max_len=args.max_len)
              if val_ex else None)
    collator = CascadePadCollator(tok)

    # ---- Training args ----
    eff_bs = args.batch * args.grad_accum
    steps_per_epoch = math.ceil(len(train_ds) / eff_bs)
    max_steps = args.smoke_steps if args.smoke_steps > 0 else -1

    targs = TrainingArguments(
        output_dir=args.out,
        num_train_epochs=args.epochs,
        max_steps=max_steps,
        per_device_train_batch_size=args.batch,
        per_device_eval_batch_size=args.batch,
        gradient_accumulation_steps=args.grad_accum,
        learning_rate=args.lr,
        warmup_ratio=args.warmup_ratio,
        lr_scheduler_type="cosine",
        optim="adamw_torch",
        bf16=True,
        logging_steps=args.logging_steps,
        save_steps=args.save_steps,
        save_total_limit=None,
        eval_strategy="steps" if val_ds else "no",
        eval_steps=args.save_steps if val_ds else None,
        report_to="none",
        seed=args.seed,
        gradient_checkpointing=True,
        gradient_checkpointing_kwargs={"use_reentrant": False},
        remove_unused_columns=False,
        dataloader_num_workers=2,
    )

    # ---- Train ----
    trainer = CascadeTrainer(
        model=model,
        lam=args.lam,
        args=targs,
        train_dataset=train_ds,
        eval_dataset=val_ds,
        data_collator=collator,
    )
    print(f"=== training: steps/epoch={steps_per_epoch}, "
          f"total={steps_per_epoch * args.epochs if max_steps < 0 else max_steps} ===",
          file=sys.stderr, flush=True)
    t0 = time.time()
    trainer.train()
    print(f"=== done in {(time.time() - t0) / 60:.1f} min ===",
          file=sys.stderr)

    # ---- Save final adapter ----
    final = Path(args.out) / "final"
    final.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(final)
    tok.save_pretrained(final)
    print(f"=== saved adapter to {final} ===", file=sys.stderr)


if __name__ == "__main__":
    main()
