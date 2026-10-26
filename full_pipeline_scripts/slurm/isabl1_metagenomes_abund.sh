#!/bin/bash

#SBATCH --array=1-2014%40
#SBATCH --mem=32G                   # Memory per task
#SBATCH -c 8                        # Number of CPU cores per task
#SBATCH --time=24:00:00             # Maximum runtime
#SBATCH --error=log/slurm/isabl1_metagenomes_abund_%A_%a.err
#SBATCH --output=log/slurm/isabl1_metagenomes_abund_%A_%a.out
#SBATCH --partition=cpu

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
mkdir -p log/slurm

# Set paths
ROOT_DIR=$(pwd)
SAMPLE_LIST="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt"
READ_METADATA="data/read_metadata.csv"
READS_DIR="data/reads"
ASSEMBLY_DIR="analyses/bacteroides_pul/metagenomes/assembly/metaspades"
PRED_DIR="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1"
ABUND_DIR="analyses/bacteroides_pul/metagenome_pul_abund"

# Get the sample for the current task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
if [[ -z "${SAMPLE}" ]]; then
  echo "No sample entry for task ${SLURM_ARRAY_TASK_ID}; exiting"
  exit 0
fi

# Locate host-depleted reads by SRA accession (same reads used for assembly)
sra=$(awk -F',' -v s="${SAMPLE}" 'NR>1{gsub(/\r/,"",$1); gsub(/\r/,"",$2); if ($2==s) {print $1; exit}}' "${READ_METADATA}")
R1=$(find "${READS_DIR}" -type f | grep -E "/${sra}.*(_R1|_1)\..*(fastq|fq)(\.gz)?$" | head -n 1)
R2=$(find "${READS_DIR}" -type f | grep -E "/${sra}.*(_R2|_2)\..*(fastq|fq)(\.gz)?$" | head -n 1)
if [[ -z "${sra}" || -z "${R1}" || -z "${R2}" ]]; then
  echo "Missing reads for ${SAMPLE} (${sra}) in ${READS_DIR}; exiting"
  exit 1
fi

CONTIGS="${ASSEMBLY_DIR}/${SAMPLE}/contigs_1000.fasta"
DBCAN_OUT="${ROOT_DIR}/${PRED_DIR}/${SAMPLE}"
SAMPLE_ABUND_DIR="${ABUND_DIR}/${SAMPLE}"
BAM="${SAMPLE_ABUND_DIR}/${SAMPLE}.bam"
mkdir -p "${SAMPLE_ABUND_DIR}"

# Step 1: Map reads to the contigs
conda activate bwa
bwa index "${CONTIGS}"
bwa mem -t 8 -o "${SAMPLE_ABUND_DIR}/${SAMPLE}.sam" "${CONTIGS}" "${R1}" "${R2}"
conda deactivate

# Step 2: Sort and index alignments
conda activate bowtie2
samtools sort -@ 8 -o "${BAM}" "${SAMPLE_ABUND_DIR}/${SAMPLE}.sam"
samtools index "${BAM}"
conda deactivate

# Step 3: Per-gene read coverage for the dbCAN gene calls
conda activate dbcan
dbcan_utils cal_coverage \
  -g "${DBCAN_OUT}/uniInput.gff" \
  -i "${BAM}" \
  -o "${SAMPLE_ABUND_DIR}/${SAMPLE}.depth.txt" \
  -t 8

# Step 4: Remove alignments to save space
rm -f "${SAMPLE_ABUND_DIR}/${SAMPLE}.sam" "${BAM}" "${BAM}.bai"

# Step 5: CAZyme substrate abundance (writes fam_substrate_abund.out, which
# lists the genes assigned to each dbCAN substrate)
cd "${SAMPLE_ABUND_DIR}" || exit 1
dbcan_utils fam_substrate_abund \
  -bt "${SAMPLE}.depth.txt" \
  -i "${DBCAN_OUT}" \
  -a TPM
