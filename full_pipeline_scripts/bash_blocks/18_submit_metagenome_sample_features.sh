#!/usr/bin/env bash
set -euo pipefail

# Submit per-sample metagenome CAZyme feature extraction (array job)
# Sums gene TPM, aligned reads, and gene counts over digestive (GH/PL/CE) CGC genes,
# their SignalP-positive subset, and the secreted host glycan / pectin subsets
# Output: analyses/bacteroides_pul/metagenome_features/per_sample/{SampleID}.tsv

N_SAMPLES=$(wc -l < analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt)
[[ "$N_SAMPLES" -gt 0 ]]
sbatch --array="1-${N_SAMPLES//[[:space:]]/}%300" full_pipeline_scripts/slurm/metagenome_sample_features.sh

echo "Submitted metagenome feature jobs. Monitor with: squeue -u $USER"
