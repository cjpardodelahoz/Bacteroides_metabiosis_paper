#!/bin/bash

#SBATCH --mem=16G                   # Memory per task
#SBATCH -c 4                        # Number of CPU cores per task
#SBATCH --time=48:00:00             # Maximum runtime
#SBATCH --error=log/slurm/bacref_signalp_%A_%a.err
#SBATCH --output=log/slurm/bacref_signalp_%A_%a.out
#SBATCH --partition=preemptable

# Array range and OFFSET are set at submission (bash_blocks/22_submit_bacref_dbcan_signalp_jobs.sh):
# task i processes line (OFFSET + i) of the genome list.

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate signalp
mkdir -p log/slurm

# Get the genome accession for the current task
GENOME_LIST="analyses/picrust_custom_traits/bacteria_genomes.txt"
LINE=$((${OFFSET:-0} + SLURM_ARRAY_TASK_ID))
ACC=$(sed -n "${LINE}p" "${GENOME_LIST}")
if [[ -z "${ACC}" ]]; then
  echo "No genome entry for line ${LINE}; exiting"
  exit 0
fi

# Set paths
PUL_DIR="analyses/picrust_custom_traits/bacref_pul_prediction/${ACC}"
PROTEINS="${PUL_DIR}/CGC.faa"
OUT_DIR="${PUL_DIR}/signalp"

# Genomes without CGCs have no proteins to score (they are zero-filled in the trait table)
if [[ ! -s "${PROTEINS}" ]]; then
  echo "No CGC proteins for ${ACC}; skipping"
  exit 0
fi

# Remove output directory if it exists
rm -rf "${OUT_DIR}"

# Predict signal peptides of CGC proteins with SignalP6
signalp6 --fastafile "${PROTEINS}" \
  --organism other \
  --output_dir "${OUT_DIR}" \
  --format none \
  --mode fast \
  --torch_num_threads 4
