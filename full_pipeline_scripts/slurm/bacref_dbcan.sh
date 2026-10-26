#!/bin/bash

#SBATCH --mem=16G                   # Memory per task
#SBATCH -c 4                        # Number of CPU cores per task
#SBATCH --time=24:00:00             # Maximum runtime
#SBATCH --error=log/slurm/bacref_dbcan_%A_%a.err
#SBATCH --output=log/slurm/bacref_dbcan_%A_%a.out
#SBATCH --partition=cpu

# Array range and OFFSET are set at submission (bash_blocks/22_submit_bacref_dbcan_signalp_jobs.sh):
# task i processes line (OFFSET + i) of the genome list.

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate dbcan
mkdir -p log/slurm

# Set paths
GENOME_LIST="analyses/picrust_custom_traits/bacteria_genomes.txt"
GENOME_DIR="analyses/picrust_custom_traits/bacteria_genomes"
OUTPUT_DIR="analyses/picrust_custom_traits/bacref_pul_prediction"
DB_DIR="/data1/xavierj/carlos/dbs/dbcan"

# Get the genome accession for the current task
LINE=$((${OFFSET:-0} + SLURM_ARRAY_TASK_ID))
ACC=$(sed -n "${LINE}p" "${GENOME_LIST}")
if [[ -z "${ACC}" ]]; then
  echo "No genome entry for line ${LINE}; exiting"
  exit 0
fi

# Decompress the genome into its output directory
GENOME_OUTPUT_DIR="${OUTPUT_DIR}/${ACC}"
mkdir -p "${GENOME_OUTPUT_DIR}"
GENOME_FNA="${GENOME_OUTPUT_DIR}/genome.fna"
gunzip -c "${GENOME_DIR}/${ACC}_genomic.fna.gz" > "${GENOME_FNA}"

# Predict genes, CAZymes, CGCs, and substrates with dbCAN
run_dbcan easy_substrate \
  --input_raw_data "${GENOME_FNA}" \
  --mode prok \
  --output_dir "${GENOME_OUTPUT_DIR}" \
  --db_dir "${DB_DIR}" \
  --input_gff "${GENOME_OUTPUT_DIR}/uniInput.gff" \
  --gff_type prodigal

# Keep only dbCAN outputs
rm -f "${GENOME_FNA}"
