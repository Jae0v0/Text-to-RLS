#!/bin/bash
# reproduce_tables.sh — regenerate the paper's result tables.
# Main table (Table V): results/table_main/reproduce_table.py (run first below).
# Ablation tables (Tables VI, VII): results/ablation/reproduce_ablation.py.
# Extraction table and figure (Table VIII, Fig. 4): results/tableVIII/reproduce_extraction.py.
#
# Usage:
#   ./scripts/reproduce_tables.sh

set -e

python3 results/table_main/reproduce_table.py

python3 results/ablation/reproduce_ablation.py

python3 results/tableVIII/reproduce_extraction.py

echo ""
echo "=== Generated ==="
ls -la results/table_main/main_results.csv
