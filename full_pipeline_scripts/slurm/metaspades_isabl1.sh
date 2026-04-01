#!/bin/bash

#SBATCH --array=1-2077%50           # update upper bound to match read_metadata.csv rows
#SBATCH --mem=48G                  # Memory per task
#SBATCH -c 16                       # Number of CPU cores per task
#SBATCH --time=120:00:00            # Maximum runtime
#SBATCH --error=log/slurm/metaspades_isabl1_%A_%a.err
#SBATCH --output=log/slurm/metaspades_isabl1_%A_%a.out
#SBATCH --partition=cpu

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh

# Set output directories
FASTP_DIR="analyses/bacteroides_pul/metagenomes/fastp"
ASSEMBLY_DIR="analyses/bacteroides_pul/metagenomes/assembly/metaspades"
READ_METADATA="data/read_metadata.csv"
READS_DIR="data/reads"

# Ensure log path exists
mkdir -p log/slurm

# Get SRA accession and SampleID from metadata (header on line 1)
meta_line=$((SLURM_ARRAY_TASK_ID + 1))
sra=$(awk -F',' -v n="${meta_line}" 'NR==n{gsub(/\r/,"",$1); print $1}' "${READ_METADATA}")
sample=$(awk -F',' -v n="${meta_line}" 'NR==n{gsub(/\r/,"",$2); print $2}' "${READ_METADATA}")

if [[ -z "${sra}" || -z "${sample}" ]]; then
      echo "No metadata row for task ${SLURM_ARRAY_TASK_ID}; exiting"
      exit 1
fi

# Locate reads by SRA accession
R1=$(find "${READS_DIR}" -type f | grep -E "/${sra}.*(_R1|_1)\..*(fastq|fq)(\.gz)?$" | head -n 1)
R2=$(find "${READS_DIR}" -type f | grep -E "/${sra}.*(_R2|_2)\..*(fastq|fq)(\.gz)?$" | head -n 1)

if [[ -z "${R1}" || -z "${R2}" ]]; then
      echo "Missing reads for ${sample} (${sra}) in ${READS_DIR}; exiting"
      exit 1
fi

# Create output directories
mkdir -p ${FASTP_DIR}/${sample} ${ASSEMBLY_DIR}/${sample}

# Step 1: Run fastp for quality control and trimming
conda activate fastp
fastp -i ${R1} -I ${R2} \
      -o ${FASTP_DIR}/${sample}/${sample}_R1_trimmed.fastq.gz \
      -O ${FASTP_DIR}/${sample}/${sample}_R2_trimmed.fastq.gz \
      --html ${FASTP_DIR}/${sample}/${sample}_fastp.html \
      --json ${FASTP_DIR}/${sample}/${sample}_fastp.json \
      --cut_front \
      --cut_right \
      --cut_mean_quality 20 \
      --length_required 30 \
      --thread 4
conda deactivate

# Step 2: Assemble the metagenome using metaSPAdes
conda activate spades
spades.py --meta \
          -1 ${FASTP_DIR}/${sample}/${sample}_R1_trimmed.fastq.gz \
          -2 ${FASTP_DIR}/${sample}/${sample}_R2_trimmed.fastq.gz \
          -o ${ASSEMBLY_DIR}/${sample} \
          -k 21,33,55,75,95 \
          -t 16 \
          -m 48
conda deactivate

# Step 3: Remove error-corrected reads and fastp-trimmed reads to save space
rm -rf ${ASSEMBLY_DIR}/${sample}/K*/*
rm -rf ${ASSEMBLY_DIR}/${sample}/corrected/*
rm -f ${FASTP_DIR}/${sample}/${sample}_R1_trimmed.fastq.gz
rm -f ${FASTP_DIR}/${sample}/${sample}_R2_trimmed.fastq.gz