#!/bin/bash
# run_cargo.sh — run CARGO end to end on RLSbench (paper §IV-§V).
#
# Usage:
#   CORPUS=<dir> API_KEY=<key> ./scripts/run_cargo.sh
#
# CORPUS holds spider_auth_templates.jsonl, practical_structure.jsonl and
# failure_cases.jsonl (supervision corpus D). Needs GPUs for the extractor (the
# paper used two NVIDIA RTX 5090), an OpenAI-compatible endpoint serving
# DeepSeek-V3.2, and the database built by setup_database.sh. The paper reports a
# single run (extractor trained for 2 epochs with AdamW at lr 2e-4).
#
# Optional: WORK (default runs/cargo), DB_NAME (default rlsbench),
#           ENDPOINT (OpenAI-compatible base URL), MODEL (default deepseek-v3.2).

set -e
CORPUS=${CORPUS:?set CORPUS to the directory with the corpus files}
API_KEY=${API_KEY:?set API_KEY}
WORK=${WORK:-runs/cargo}
DB_NAME=${DB_NAME:-rlsbench}
MODEL=${MODEL:-deepseek-v3.2}
ENDPOINT_ARG=${ENDPOINT:+--endpoint $ENDPOINT}
SCHEMA=data/RLSbench/schema
mkdir -p "$WORK"

echo "=== 1. Supervision corpus D ==="
python3 cargo/extractor/train/build_cascade_dataset.py \
  --auth-templates "$CORPUS/spider_auth_templates.jsonl" \
  --practical-structure "$CORPUS/practical_structure.jsonl" \
  --failure-cases "$CORPUS/failure_cases.jsonl" \
  --requirements data/RLSbench/requirements.json \
  --out "$WORK/cascade_train.jsonl" --dev-out "$WORK/cascade_dev.jsonl"

echo "=== 2. Extractor input and demonstration pool ==="
python3 cargo/extractor/infer/build_test_input.py \
  --policies data/RLSbench/single_policy/policies.json \
  --test-cases data/RLSbench/single_policy/test_cases.json \
  --schema "$SCHEMA/trimmed_schema.sql" \
  --out "$WORK/test_text2rls.jsonl"
python3 cargo/retrieval/icl/validate_pool.py \
  --kb cargo/retrieval/icl/kb_practical_structure.json \
  --db_name "$DB_NAME" --out "$WORK/kb_validated.json"

RUN="$WORK/run"
mkdir -p "$RUN"

echo "=== 3. Cascaded fine-tuning ==="
python3 cargo/extractor/train/train_codes3b_cascade.py \
  --train "$WORK/cascade_train.jsonl" --val "$WORK/cascade_dev.jsonl" \
  --out "$RUN/adapter"

echo "=== 4. Top-K cascaded decoding ==="
python3 cargo/extractor/infer/infer_extractor_topk.py \
  --adapter "$RUN/adapter/final" --test "$WORK/test_text2rls.jsonl" \
  --out "$RUN/cascade_top3.jsonl"

echo "=== 5. Top-K candidate selection ==="
python3 cargo/retrieval/rerank/rerank_extractor_topk.py \
  --cascade-jsonl "$RUN/cascade_top3.jsonl" --test-jsonl "$WORK/test_text2rls.jsonl" \
  --keyword-map cargo/extractor/data/keyword_map_eta.json \
  --out "$RUN/cascade_reranked.jsonl"

echo "=== 6. Demonstration retrieval and prompts ==="
python3 cargo/retrieval/icl/build_op_struct_prompts.py \
  --policies data/RLSbench/single_policy/policies.json \
  --test-cases data/RLSbench/single_policy/test_cases.json \
  --kb "$WORK/kb_validated.json" \
  --schema "$SCHEMA/trimmed_schema.sql" \
  --runtime-context "$SCHEMA/runtime_context/runtime_context_spec.json" \
  --job-roles "$SCHEMA/runtime_context/job_role_vocab.json" \
  --extractor "$RUN/cascade_reranked.jsonl" \
  --output "$RUN/prompts.json"

echo "=== 7. Policy generation ==="
python3 cargo/generation/run_gen_from_prompts.py \
  --prompts "$RUN/prompts.json" --model "$MODEL" $ENDPOINT_ARG \
  --api_key "$API_KEY" --out "$RUN/predictions.json"

echo "=== 8. Execution-based evaluation ==="
./scripts/run_evaluation.sh "$RUN/predictions.json" "$DB_NAME" "$RUN/execution.json" single
