#!/usr/bin/env bash
set -euo pipefail

# Submit SignalP and read-mapping/abundance jobs for metagenomes with dbCAN output
# Both are array jobs over analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt
#   - isabl1_metagenomes_signalp.sh: SignalP6 on CGC proteins
#   - isabl1_metagenomes_abund.sh: map reads to contigs, per-gene coverage, and
#     dbCAN-sub substrate gene lists (dbcan_utils)
# Outputs:
#   - SignalP: analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/{SampleID}/signalp/prediction_results.txt
#   - Coverage: analyses/bacteroides_pul/metagenome_pul_abund/{SampleID}/{SampleID}.depth.txt
#   - Substrates: analyses/bacteroides_pul/metagenome_pul_abund/{SampleID}/fam_substrate_abund.out

sbatch full_pipeline_scripts/slurm/isabl1_metagenomes_signalp.sh
sbatch full_pipeline_scripts/slurm/isabl1_metagenomes_abund.sh

echo "Submitted metagenome SignalP and abundance jobs. Monitor with: squeue -u $USER"
