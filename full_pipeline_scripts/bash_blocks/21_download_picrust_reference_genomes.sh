#!/usr/bin/env bash
set -euo pipefail

# Download GTDB r214.1 representative genomes and keep the PICRUSt2 bac_ref genomes
# Output: analyses/picrust_custom_traits/bacteria_genomes/{accession}_genomic.fna.gz

sbatch full_pipeline_scripts/slurm/download_picrust_reference_genomes.sh

echo "Submitted reference genome download job. Monitor with: squeue -u $USER"
