#!/usr/bin/env bash
set -euo pipefail

# Submit dbCAN (CAZyme annotation) and SignalP (secretion signal prediction) jobs on cluster
# These are array jobs for parallel processing of MAGs
# Submits four separate array jobs for efficient parallelization:
#   - isabl1_mags_dbcan_1-9999.sh
#   - isabl1_mags_dbcan_10000-10360.sh
#   - isabl1_mags_signalp_1-9999.sh
#   - isabl1_mags_signalp_10000-10360.sh
# Outputs:
#   - dbCAN: analyses/bacteroides_pul/mag_pul_prediction/isabl1/{MAG}/cgc_standard_out.tsv
#   - SignalP: analyses/bacteroides_pul/mag_pul_prediction/isabl1/{MAG}/signalp/prediction_results.txt

sbatch full_pipeline_scripts/slurm/isabl1_mags_dbcan_1-9999.sh
sbatch full_pipeline_scripts/slurm/isabl1_mags_dbcan_10000-10360.sh

sbatch full_pipeline_scripts/slurm/isabl1_mags_signalp_1-9999.sh
sbatch full_pipeline_scripts/slurm/isabl1_mags_signalp_10000-10360.sh

echo "Submitted dbCAN and SignalP annotation jobs. Monitor with: squeue -u $USER"
