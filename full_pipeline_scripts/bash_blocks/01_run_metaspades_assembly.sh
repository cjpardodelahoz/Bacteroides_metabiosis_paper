#!/usr/bin/env bash
set -euo pipefail

# Submit per-sample metagenome assembly job (fastp QC + metaSPAdes)
# This is an array job that processes samples in parallel
# Job IDs are read from data/read_metadata.csv (one sample per row after header)
# Outputs: 
#   - Trimmed reads: analyses/bacteroides_pul/metagenomes/fastp/{SampleID}/
#   - Assemblies: analyses/bacteroides_pul/metagenomes/assembly/metaspades/{SampleID}/contigs.fasta

sbatch full_pipeline_scripts/slurm/metaspades_isabl1.sh

echo "Submitted metaSPAdes assembly jobs. Monitor with: squeue -u $USER"
