#!/usr/bin/env bash
set -euo pipefail

mkdir -p analyses/bacteroides_pul/mag_pul_summary

NC_MAGS="analyses/bacteroides_pul/isabl1_nc_mags.txt"
CGC_OUT="analyses/bacteroides_pul/mag_pul_summary/compiled_cgcs.tsv"

FIRST_MAG=$(head -n 1 "${NC_MAGS}")
FIRST_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${FIRST_MAG}/cgc_standard_out.tsv"

echo -e "mag\t$(head -n 1 "${FIRST_FILE}")" > "${CGC_OUT}"

while IFS= read -r MAG; do
  TSV_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${MAG}/cgc_standard_out.tsv"
  if [ -f "${TSV_FILE}" ]; then
    tail -n +2 "${TSV_FILE}" | awk -v mag="${MAG}" 'BEGIN{OFS="\t"} {print mag, $0}' >> "${CGC_OUT}"
    echo "Processed: ${MAG}"
  else
    echo "Warning: File not found for ${MAG}"
  fi
done < "${NC_MAGS}"
