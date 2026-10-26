#!/usr/bin/env bash
set -euo pipefail

# Submit dbCAN and SignalP on the PICRUSt2 reference genomes
# SLURM array size is capped, so the genome list is processed in three batches;
# OFFSET shifts each batch to its lines of analyses/picrust_custom_traits/bacteria_genomes.txt.
# Each SignalP batch starts after the matching dbCAN batch has finished.
# Outputs:
#   - dbCAN: analyses/picrust_custom_traits/bacref_pul_prediction/{accession}/
#   - SignalP: analyses/picrust_custom_traits/bacref_pul_prediction/{accession}/signalp/prediction_results.txt

N_GENOMES=$(wc -l < analyses/picrust_custom_traits/bacteria_genomes.txt)
BATCH_SIZE=9999

for OFFSET in $(seq 0 ${BATCH_SIZE} $((N_GENOMES - 1))); do
  N_TASKS=$(( N_GENOMES - OFFSET < BATCH_SIZE ? N_GENOMES - OFFSET : BATCH_SIZE ))
  DBCAN_JOB=$(sbatch --parsable --array=1-${N_TASKS}%500 --export=ALL,OFFSET=${OFFSET} \
    full_pipeline_scripts/slurm/bacref_dbcan.sh)
  sbatch --array=1-${N_TASKS}%500 --export=ALL,OFFSET=${OFFSET} --dependency=afterany:${DBCAN_JOB} \
    full_pipeline_scripts/slurm/bacref_signalp.sh
  echo "Submitted genomes $((OFFSET + 1))-$((OFFSET + N_TASKS)) (dbCAN job ${DBCAN_JOB})"
done

echo "Submitted reference genome dbCAN and SignalP jobs. Monitor with: squeue -u $USER"
