#!/usr/bin/env bash
set -euo pipefail

# Submit dbCAN (genes, CAZymes, CGCs, substrates) on each metagenome assembly
# This is an array job over analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt
# Input: analyses/bacteroides_pul/metagenomes/assembly/metaspades/{SampleID}/contigs_1000.fasta (section B)
# Output: analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/{SampleID}/
#   (uniInput.gff, CGC.faa, cgc_standard_out.tsv, dbCANsub_hmm_results.tsv, ...)

N_SAMPLES=$(wc -l < analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt)
[[ "$N_SAMPLES" -gt 0 ]]
sbatch --array="1-${N_SAMPLES//[[:space:]]/}%100" full_pipeline_scripts/slurm/isabl1_metagenomes_dbcan.sh

echo "Submitted metagenome dbCAN jobs. Monitor with: squeue -u $USER"
