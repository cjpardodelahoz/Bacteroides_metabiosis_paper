#!/usr/bin/env bash
set -euo pipefail

# Write the Liao et al. 2021 ASV sequences as FASTA for PICRUSt2 placement
# Input: data/Liao_etal_2021/tblASVtaxonomy_silva132_v4v5_filter.csv (columns ASV, Sequence)
# Output: analyses/picrust_custom_traits/placement/asv_sequences.fasta

mkdir -p analyses/picrust_custom_traits/placement

python3 - <<'PYEOF'
import csv

# Numeric ASV order (ASV_1, ASV_2, ...), matching the placement input of the published predictions
with open("data/Liao_etal_2021/tblASVtaxonomy_silva132_v4v5_filter.csv", newline="") as f:
    rows = sorted(csv.DictReader(f), key=lambda r: int(r["ASV"].split("_")[1]))
with open("analyses/picrust_custom_traits/placement/asv_sequences.fasta", "w") as out:
    for row in rows:
        out.write(">%s\n%s\n" % (row["ASV"], row["Sequence"]))
PYEOF

echo "ASV sequences: $(grep -c '^>' analyses/picrust_custom_traits/placement/asv_sequences.fasta)"
echo "Successfully created: analyses/picrust_custom_traits/placement/asv_sequences.fasta"
