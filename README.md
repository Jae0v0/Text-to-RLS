# Text-to-RLS: Towards Constraint-Anchored Row-Level Security in Natural Language Database Interfaces

Code, data and results for the ICDE 2027 paper of the same title.

The repository contains:

- **RLSbench**, a benchmark of natural-language authorization requirements paired with reference PostgreSQL `CREATE POLICY` statements and executable test cases.
- **CARGO** (constraint-anchored RLS generation with operation-routed demonstrations), the synthesis framework proposed in the paper.
- The predictions and execution outputs behind every number in the paper's result tables and figures, with scripts that recompute them.

## Repository layout

```
Text-to-RLS/
├── data/RLSbench/
│   ├── requirements.json        550 requirements (490 single-policy + 60 multi-policy), with policy_type and tier (L1-L4)
│   ├── schema/                  enterprise schema (cleaned_schema.sql, trimmed_schema.sql) and runtime context
│   ├── single_policy/           policies.json (490 reference policies), test_cases.json (3,100 tests)
│   └── multi_policy/            multi_policy.json (60 bundles, 169 policies), test_cases.json (686 tests), tools/
├── cargo/
│   ├── extractor/               supervision corpus builder, cascaded fine-tuning, top-K cascaded decoding
│   ├── retrieval/               top-K candidate selection (rerank/), demonstration pool and retrieval (icl/)
│   └── generation/              policy generation for CARGO and for the baselines
├── evaluation/                  test-case executor (run_test_cases.py) and metrics (evaluate.py)
├── baselines/prompts/           prompts and demonstration ids of the baseline runs
├── results/                     predictions, executor outputs and reproduction scripts (see below)
└── scripts/                     setup_database.sh, run_evaluation.sh, run_cargo.sh, reproduce_tables.sh
```

## RLSbench in numbers

| | |
|---|---|
| Natural-language requirements | 550 (490 single-policy + 60 multi-policy bundles) |
| Reference `CREATE POLICY` statements | 659 (490 + 169) |
| Enterprise schemas | 8 (45 tables, 1,707 columns in `trimmed_schema.sql`) |
| Executable test cases | 3,786 (3,100 single-policy + 686 multi-policy) |
| Test cases by purpose | 662 positive, 1,497 negative, 1,627 missing-session |
| Difficulty (L1 / L2 / L3 / L4) | 68 / 138 / 207 / 137 |
| Metrics | PCS, BA, OPR, UPR, Sec@0FP, DDeny, IA |

`trimmed_schema.sql` is the schema given to the models (Table II of the paper). `cleaned_schema.sql` is the full database the evaluator installs (68 tables in 9 schemas).

Each multi-policy bundle is a set of policies on one table; 17 bundles combine an `AS RESTRICTIVE FOR ALL` tenant-isolation policy with `AS PERMISSIVE` grants. A bundle is evaluated as a unit: all its policies are installed before its tests run.

## Requirements

- PostgreSQL 16, with a user that can create databases and roles (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` are honored).
- Python 3.9+ with `psycopg2`. CARGO additionally needs `torch`, `transformers`, `peft` and `scikit-learn`, and the generation scripts need `openai` (any OpenAI-compatible endpoint).

## Quick start: evaluate predictions

```bash
# 1. Build the clean RLSbench database
./scripts/setup_database.sh rlsbench

# 2. Evaluate a predictions file (SUITE = single | multi); each run uses a fresh clone of the database
./scripts/run_evaluation.sh my_predictions.json rlsbench results/my_eval.json single
```

A predictions file is a JSON list of `{"id": <item id>, "predicted_sql": "<CREATE POLICY ...>"}`. Each policy is installed under a non-superuser role without `BYPASSRLS`, with row-level security enabled and forced on the target table; the session context is injected with `set_config` before each test. The script prints the seven metrics of the paper (Eqs. 4-10). Tests of an item whose policy is missing or fails to install count as failed.

To check the harness itself, evaluate the reference policies on a copy of the clean database:

```bash
createdb -T rlsbench rlsbench_gold
python3 evaluation/run_test_cases.py --mode gold --db_name rlsbench_gold \
  --test_cases_path data/RLSbench/single_policy/test_cases.json \
  --benchmark_path  data/RLSbench/single_policy/policies.json \
  --output_path results/gold_single.json
```

The reference policies pass all 3,100 single-policy and all 686 multi-policy tests.

## Reproducing the paper's tables and figures

```bash
./scripts/reproduce_tables.sh
```

recomputes every reported number from the files in `results/` (no database or API needed) and prints any cell that differs from the paper:

| Paper | Files | Check |
|---|---|---|
| Table V (19 systems x 7 metrics) | `results/table_main/<row>/{predictions,execution}.json` | `results/table_main/reproduce_table.py` |
| Tables VI and VII (ablations) | `results/ablation/<row>/`, plus `table_main/` for the baseline and full CARGO rows | `results/ablation/reproduce_ablation.py` |
| Table VIII and Fig. 4 (extraction) | `results/tableVIII/*.jsonl` | `results/tableVIII/reproduce_extraction.py` |
| Fig. 3 (a)-(c) | `results/fig3/viz_data.json` | `results/fig3/gen_fig_*.py` |

All result files cover the 490 single-policy items.

## Running CARGO

```bash
CORPUS=/path/to/corpus API_KEY=... ./scripts/run_cargo.sh
```

`CORPUS` holds the supervision corpus D (`spider_auth_templates.jsonl`, `practical_structure.jsonl`, `failure_cases.jsonl`). The script runs the pipeline of Sections IV and V with the paper's settings:

| Step | Script | Settings |
|---|---|---|
| Supervision corpus D | `cargo/extractor/train/build_cascade_dataset.py` | Authorization-Template, Practical-Structure and Failure-Case examples |
| Cascaded fine-tuning of CodeS-3B | `cargo/extractor/train/train_codes3b_cascade.py` | LoRA rank 16, alpha 32, dropout 0.05; AdamW, lr 2e-4, 2 epochs; lambda = 0.4 |
| Top-K cascaded decoding | `cargo/extractor/infer/infer_extractor_topk.py` | diverse beam search, B_S = B_A = K = 3 |
| Top-K candidate selection | `cargo/retrieval/rerank/rerank_extractor_topk.py` | (alpha_cf, alpha_gr, alpha_ps) = (0.4, 0.4, 0.2), PMI keyword map `cargo/extractor/data/keyword_map_eta.json` |
| Demonstration pool | `cargo/retrieval/icl/validate_pool.py` | enterprise-schema entries pass a `CREATE POLICY` round trip |
| Operation-routed retrieval and prompt | `cargo/retrieval/icl/build_op_struct_prompts.py`, `op_struct_icl.py` | (alpha_s, alpha_a) = (0.3, 0.7), k = 5, xi = 0.3, leave-one-out |
| Policy generation | `cargo/generation/run_gen_from_prompts.py` | DeepSeek-V3.2, temperature 0, 4,096 output tokens |
| Evaluation | `scripts/run_evaluation.sh` | as above |

The paper reports a single run. Fine-tuning used two NVIDIA RTX 5090 GPUs.

### Demonstration pool

`cargo/retrieval/icl/kb_practical_structure.json` holds the Practical-Structure part of the demonstration pool K:

- 1,984 Practical-Structure entries instantiated on the enterprise schema (`db_id = enterprise_rls_db`);
- 137 policies taken verbatim from the Supabase documentation, the Supabase example repository and the PostgREST documentation. Each entry records its `source_url`, `source_section` and `license`.

CARGO's pool adds the other RLSbench items (leave-one-out on the requirement). The 5-shot baselines (`cargo/generation/generate_predictions.py`, strategy `random`, seed 42) draw from the enterprise-schema Practical-Structure entries, sequentially in item order; this reproduces the demonstration ids of all 490 items in `baselines/prompts/demos_icl_random.json`.

## Baselines

`cargo/generation/generate_predictions.py` (API models) and `generate_predictions_local.py` (local models) generate the 0-shot and 5-shot baselines of Table V. `baselines/prompts/` keeps the prompts and demonstration ids of the baseline runs. `demos_icl_random.json` (the random 5-shot demonstrations of Table V) covers all 490 items; the other files cover 481 items and do not include the items with ids 542-550.

## Citation

```bibtex
@inproceedings{fan2027text2rls,
  title     = {Text-to-RLS: Towards Constraint-Anchored Row-Level Security in Natural Language Database Interfaces},
  author    = {Fan, Jiaqi and Wan, Zhuoyue and Zhang, Chen Jason and Wei, Xiao-Yong and Li, Haoyang and Song, Yuanfeng and Ni, Wangze and Wong, Raymond Chi-Wing},
  booktitle = {Proceedings of the IEEE International Conference on Data Engineering (ICDE)},
  year      = {2027}
}
```

## License

Code is released under the MIT License and data under CC BY 4.0. The 137 Supabase and PostgREST examples in the demonstration pool keep their original licenses (Supabase: Apache-2.0; PostgREST documentation: MIT), recorded per entry.
