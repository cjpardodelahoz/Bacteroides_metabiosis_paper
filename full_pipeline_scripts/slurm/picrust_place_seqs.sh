#!/bin/bash

#SBATCH --mem=64G                   # Memory
#SBATCH -c 16                       # Number of CPU cores
#SBATCH --time=48:00:00             # Maximum runtime
#SBATCH --error=log/slurm/picrust_place_seqs_%j.err
#SBATCH --output=log/slurm/picrust_place_seqs_%j.out
#SBATCH --partition=cpu

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate picrust2
mkdir -p log/slurm

# Set paths
PLACEMENT_DIR="analyses/picrust_custom_traits/placement"
ASV_FASTA="${PLACEMENT_DIR}/asv_sequences.fasta"
TREE="${PLACEMENT_DIR}/out.tre"
MARKER="${PLACEMENT_DIR}/marker_predicted_and_nsti.tsv.gz"
# PICRUSt2 bacterial reference (the only reference with a CAZy trait table; see the custom trait wiki)
BAC_REF=$(python -c "import os, picrust2; print(os.path.join(os.path.dirname(picrust2.__file__), 'default_files/bacteria/bac_ref'))")

mkdir -p "${PLACEMENT_DIR}/intermediate"

# Step 1: Place ASVs into the PICRUSt2 bacterial reference tree
place_seqs.py \
  --study_fasta "${ASV_FASTA}" \
  --ref_dir "${BAC_REF}" \
  --out_tree "${TREE}" \
  --processes 16 \
  --intermediate "${PLACEMENT_DIR}/intermediate" \
  --min_align 0.80 \
  --verbose

# Step 2: Predict 16S copy number and NSTI for each ASV
hsp.py \
  --calculate_NSTI \
  --tree "${TREE}" \
  --in_trait 16S \
  --reference bac \
  --output "${MARKER}" \
  --processes 16

# Remove placement intermediates
rm -rf "${PLACEMENT_DIR}/intermediate"
