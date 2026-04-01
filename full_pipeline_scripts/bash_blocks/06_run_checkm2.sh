#!/usr/bin/env bash
set -euo pipefail

# Run CheckM2 on compiled VAMB bins
# Input: analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins/*.fna
# Output: analyses/bacteroides_pul/checkm2/quality_report.tsv

sbatch full_pipeline_scripts/slurm/checkm2_isabl1.sh

echo "Submitted CheckM2 job. Monitor with: squeue -u $USER"
