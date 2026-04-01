#!/usr/bin/env bash
set -euo pipefail

# Run GTDB-Tk classification on compiled VAMB bins
# Input: analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins/*.fna
# Output: analyses/bacteroides_pul/gtdb/gtdbtk.bac120.summary.tsv
# Optional: set GTDBTK_MASH_DB before running if your cluster requires explicit mash DB path.

sbatch full_pipeline_scripts/slurm/isabl1_gtdb.sh

echo "Submitted GTDB-Tk job. Monitor with: squeue -u $USER"
