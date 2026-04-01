#!/bin/bash

#SBATCH --output=log/slurm/isabl1_gtdb.out
#SBATCH --error=log/slurm/isabl1_gtdb.err
#SBATCH --time=168:00:00
#SBATCH --cpus-per-task=64
#SBATCH --mem=256G
#SBATCH --partition=cpu

# Activate the GTDB environment
source $(conda info --base)/etc/profile.d/conda.sh
conda activate gtdb

# Set paths
BIN_DIR="analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins"
OUTPUT_DIR="analyses/bacteroides_pul/gtdb"

mkdir -p log/slurm "${OUTPUT_DIR}"

# Optionally provide an external mash DB path via env var:
#   export GTDBTK_MASH_DB=/path/to/gtdb_ref_sketch.msh
if [[ -n "${GTDBTK_MASH_DB:-}" ]]; then
  gtdbtk classify_wf \
    --genome_dir "${BIN_DIR}" \
    --out_dir "${OUTPUT_DIR}" \
    --cpus 64 \
    --mash_db "${GTDBTK_MASH_DB}"
else
  gtdbtk classify_wf \
    --genome_dir "${BIN_DIR}" \
    --out_dir "${OUTPUT_DIR}" \
    --cpus 64
fi
