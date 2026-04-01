#!/bin/bash

#SBATCH --array=1-361
#SBATCH --mem=16G         # Memory per task
#SBATCH -c 4              # Number of CPU cores per task
#SBATCH --time=48:00:00   # Maximum runtime
#SBATCH --error=log/slurm/isabl1_mags_signalp_%A_%a.err
#SBATCH --output=log/slurm/isabl1_mags_signalp_%A_%a.out
#SBATCH --partition=preemptable

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate signalp
mkdir -p log/slurm

# Get the MAG name for the current task
MAG=$(tail -n 361 analyses/bacteroides_pul/isabl1_nc_mags.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
if [[ -z "${MAG}" ]]; then
    echo "No MAG entry for task ${SLURM_ARRAY_TASK_ID}; exiting"
    exit 0
fi

# Set paths
PUL_DIR="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${MAG}"
PROTEINS="${PUL_DIR}/CGC.faa"
OUT_DIR="${PUL_DIR}/signalp"

if [[ ! -f "${PROTEINS}" ]]; then
    echo "Protein file not found: ${PROTEINS}; exiting"
    exit 1
fi

# Run SignalP
signalp6 --fastafile ${PROTEINS} \
    --organism other \
    --output_dir ${OUT_DIR} \
    --format none \
    --mode fast \
    --torch_num_threads 4