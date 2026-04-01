#!/usr/bin/env bash
set -euo pipefail

# Submit multi-sample VAMB binning job
# This is an array job: one task per PatientID (reads patient sample lists created in step 03)
# Requires: successful assemblies from step 01, patient sample lists from step 03
# Outputs:
#   - VAMB bins: analyses/bacteroides_pul/binning/short/isabl1/vamb/multi/{PatientID}/vambout/bins/*.fna

sbatch full_pipeline_scripts/slurm/vamb_multi_isabl1.sh

echo "Submitted VAMB binning jobs. Monitor with: squeue -u $USER"
