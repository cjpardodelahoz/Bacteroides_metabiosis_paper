#!/bin/bash

#SBATCH --array=1-2014%500
#SBATCH --mem=16G                   # Memory per task
#SBATCH -c 4                        # Number of CPU cores per task
#SBATCH --time=48:00:00             # Maximum runtime
#SBATCH --error=log/slurm/isabl1_metagenomes_signalp_%A_%a.err
#SBATCH --output=log/slurm/isabl1_metagenomes_signalp_%A_%a.out
#SBATCH --partition=preemptable

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate signalp
mkdir -p log/slurm

# Get the sample for the current task
SAMPLE_LIST="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
if [[ -z "${SAMPLE}" ]]; then
  echo "No sample entry for task ${SLURM_ARRAY_TASK_ID}; exiting"
  exit 0
fi

# Set paths
PUL_DIR="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/${SAMPLE}"
PROTEINS="${PUL_DIR}/CGC.faa"
OUT_DIR="${PUL_DIR}/signalp"

# Remove output directory if it exists
rm -rf "${OUT_DIR}"

# Predict signal peptides of CGC proteins with SignalP6
signalp6 --fastafile "${PROTEINS}" \
  --organism other \
  --output_dir "${OUT_DIR}" \
  --format none \
  --mode fast \
  --torch_num_threads 4
