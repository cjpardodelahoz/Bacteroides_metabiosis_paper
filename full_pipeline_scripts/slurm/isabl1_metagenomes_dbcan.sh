#!/bin/bash

#SBATCH --array=1-2053%100          # update upper bound to match metaspades_successful_samples.txt rows
#SBATCH --mem=16G                   # Memory per task
#SBATCH -c 8                        # Number of CPU cores per task
#SBATCH --time=24:00:00             # Maximum runtime
#SBATCH --error=log/slurm/isabl1_metagenomes_dbcan_%A_%a.err
#SBATCH --output=log/slurm/isabl1_metagenomes_dbcan_%A_%a.out
#SBATCH --partition=cpu

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate dbcan
mkdir -p log/slurm

# Set paths
SAMPLE_LIST="analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt"
ASSEMBLY_DIR="analyses/bacteroides_pul/metagenomes/assembly/metaspades"
OUTPUT_DIR="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1"
DB_DIR="/data1/xavierj/carlos/dbs/dbcan"

# Get the sample for the current task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
if [[ -z "${SAMPLE}" ]]; then
  echo "No sample entry for task ${SLURM_ARRAY_TASK_ID}; exiting"
  exit 0
fi

# Contigs >= 1000 bp (written during VAMB binning, section B)
CONTIGS="${ASSEMBLY_DIR}/${SAMPLE}/contigs_1000.fasta"
if [[ ! -s "${CONTIGS}" ]]; then
  echo "Contigs not found: ${CONTIGS}; exiting"
  exit 1
fi

SAMPLE_OUTPUT_DIR="${OUTPUT_DIR}/${SAMPLE}"
mkdir -p "${SAMPLE_OUTPUT_DIR}"

# Predict genes, CAZymes, CGCs, and substrates with dbCAN
run_dbcan easy_substrate \
  --input_raw_data "${CONTIGS}" \
  --mode meta \
  --output_dir "${SAMPLE_OUTPUT_DIR}" \
  --db_dir "${DB_DIR}" \
  --input_gff "${SAMPLE_OUTPUT_DIR}/uniInput.gff" \
  --gff_type prodigal \
  --threads 8
