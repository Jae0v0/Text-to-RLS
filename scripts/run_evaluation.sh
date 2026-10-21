#!/bin/bash
# run_evaluation.sh — evaluate a predictions file against RLSbench test cases.
#
# Usage:
#   ./scripts/run_evaluation.sh <predictions.json> [DB_NAME] [OUTPUT.json] [SUITE]
#
# SUITE = single (default): 490 single-policy items, 3,100 test cases.
# SUITE = multi           : 60 multi-policy bundles, 686 test cases (a bundle's
#                           policies are installed together before its tests run).
# DB_NAME (default rlsbench) is the clean database built by setup_database.sh; the
# evaluation runs on a fresh clone of it, which is dropped afterwards.
# Default OUTPUT = results/<basename>_eval.json.

set -e
PRED=${1:?Usage: $0 <predictions.json> [DB_NAME] [OUTPUT.json] [SUITE]}
DB_NAME=${2:-rlsbench}
DEFAULT_OUT="results/$(basename "${PRED%.*}")_eval.json"
OUT=${3:-$DEFAULT_OUT}
SUITE=${4:-single}

TC=data/RLSbench/${SUITE}_policy/test_cases.json
if [ "$SUITE" = multi ]; then
  BP=data/RLSbench/multi_policy/multi_policy.json
else
  BP=data/RLSbench/single_policy/policies.json
fi

RUN_DB="${DB_NAME}_run_$$"
psql -d postgres -qc "CREATE DATABASE $RUN_DB TEMPLATE $DB_NAME;"
TEST_ROLE="rls_test_$$"
trap 'psql -d postgres -qc "DROP DATABASE IF EXISTS $RUN_DB;" -c "DROP ROLE IF EXISTS $TEST_ROLE;"' EXIT

mkdir -p "$(dirname "$OUT")"

echo "=== Running evaluation ==="
echo "  predictions : $PRED"
echo "  test cases  : $TC"
echo "  database    : $RUN_DB (fresh clone of $DB_NAME)"
echo "  output      : $OUT"

RLS_TEST_ROLE="$TEST_ROLE" python3 evaluation/run_test_cases.py \
  --test_cases_path "$TC" \
  --benchmark_path  "$BP" \
  --predictions_path "$PRED" \
  --db_name "$RUN_DB" \
  --mode pred \
  --output_path "$OUT"

echo ""
echo "=== Summary metrics (Eqs. 4-10) ==="
python3 -c "
import json, sys
m = json.load(open(sys.argv[1]))['metrics']
for name, key in [('PCS', 'policy_creation_success'), ('BA', 'behavior_accuracy'),
                  ('OPR', 'over_privilege_rate'), ('UPR', 'under_privilege_rate'),
                  ('Sec@0FP', 'security_pass_0fp'), ('DDeny', 'default_deny_pass_rate'),
                  ('IA', 'intent_accuracy')]:
    print(f'  {name:<8} {m[key]:.3f}')
" "$OUT"
