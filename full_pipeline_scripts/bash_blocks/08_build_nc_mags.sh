#!/usr/bin/env bash
set -euo pipefail

# Build MAG QC/taxonomy summary and filtered NC MAG list.
# Inputs:
#   - analyses/bacteroides_pul/checkm2/quality_report.tsv
#   - analyses/bacteroides_pul/gtdb/gtdbtk.bac120.summary.tsv
# Outputs:
#   - analyses/bacteroides_pul/mag_pul_summary/mag_qc_taxonomy_summary.tsv
#   - analyses/bacteroides_pul/isabl1_nc_mags.txt

Rscript full_pipeline_scripts/build_nc_mags.R
