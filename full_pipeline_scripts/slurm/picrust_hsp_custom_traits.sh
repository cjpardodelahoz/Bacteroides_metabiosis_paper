#!/bin/bash

#SBATCH --mem=64G                   # Memory
#SBATCH -c 16                       # Number of CPU cores
#SBATCH --time=12:00:00             # Maximum runtime
#SBATCH --error=log/slurm/picrust_hsp_custom_traits_%j.err
#SBATCH --output=log/slurm/picrust_hsp_custom_traits_%j.out
#SBATCH --partition=cpu

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate picrust2
mkdir -p log/slurm

# Set paths
TREE="analyses/picrust_custom_traits/placement/out.tre"
TRAIT_DIR="analyses/picrust_custom_traits"
HSP_DIR="analyses/picrust_custom_traits/hsp"

mkdir -p "${HSP_DIR}"

# Hidden-state prediction (maximum parsimony) of the custom traits for each ASV.
# chunk_size 34 spreads the 540 traits across all 16 processes.
for TABLE in secreted all_digestive; do
  hsp.py \
    --tree "${TREE}" \
    --observed_trait_table "${TRAIT_DIR}/custom_trait_table_${TABLE}.tsv" \
    --output "${HSP_DIR}/cazy_custom_predicted_${TABLE}.tsv.gz" \
    --hsp_method mp \
    --check \
    --processes 16 \
    --chunk_size 34 \
    --seed 100 \
    --verbose
done
