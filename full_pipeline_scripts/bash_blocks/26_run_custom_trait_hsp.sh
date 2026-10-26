#!/usr/bin/env bash
set -euo pipefail

# Predict the custom CAZyme traits for each ASV on the placed tree (hidden-state prediction)
# Outputs:
#   - analyses/picrust_custom_traits/hsp/cazy_custom_predicted_secreted.tsv.gz
#   - analyses/picrust_custom_traits/hsp/cazy_custom_predicted_all_digestive.tsv.gz

sbatch full_pipeline_scripts/slurm/picrust_hsp_custom_traits.sh

echo "Submitted PICRUSt2 custom trait prediction job. Monitor with: squeue -u $USER"
