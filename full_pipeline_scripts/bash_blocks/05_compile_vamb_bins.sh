#!/usr/bin/env bash
set -euo pipefail

# Compile all patient VAMB bins into one folder
# Copies all .fna files from per-patient VAMB output directories into a single directory
# This consolidates bins for downstream processing (dbCAN, SignalP, PUL prediction)
# Output structure: analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins/{PatientID}_{BinName}.fna

SRC_BASE="analyses/bacteroides_pul/binning/short/isabl1/vamb/multi"
DEST_BASE="analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins"
mkdir -p "${DEST_BASE}"

find "${SRC_BASE}" -mindepth 1 -maxdepth 1 -type d | while read -r patient_dir; do
  patient=$(basename "${patient_dir}")
  bins_dir="${patient_dir}/vambout/bins"
  [ -d "${bins_dir}" ] || continue
  for fna in "${bins_dir}"/*.fna; do
    [ -e "$fna" ] || continue
    cp "$fna" "${DEST_BASE}/${patient}_$(basename "$fna")"
  done
done

echo "Successfully compiled VAMB bins to: ${DEST_BASE}"
