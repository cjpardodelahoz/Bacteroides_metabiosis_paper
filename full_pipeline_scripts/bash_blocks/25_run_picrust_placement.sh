#!/usr/bin/env bash
set -euo pipefail

# Place ASVs into the PICRUSt2 bacterial reference tree and predict 16S copy number and NSTI
# Outputs:
#   - analyses/picrust_custom_traits/placement/out.tre
#   - analyses/picrust_custom_traits/placement/marker_predicted_and_nsti.tsv.gz

sbatch full_pipeline_scripts/slurm/picrust_place_seqs.sh

echo "Submitted PICRUSt2 placement job. Monitor with: squeue -u $USER"
