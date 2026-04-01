#!/usr/bin/env bash
set -euo pipefail

NC_MAGS="analyses/bacteroides_pul/isabl1_nc_mags.txt"
PUL_OUT="analyses/bacteroides_pul/mag_pul_summary/compiled_puls.tsv"

FIRST_MAG=$(head -n 1 "${NC_MAGS}")
FIRST_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${FIRST_MAG}/substrate_prediction.tsv"

echo -e "mag\t$(sed -n '1p' "${FIRST_FILE}")" > "${PUL_OUT}"

while IFS= read -r MAG; do
  TSV_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${MAG}/substrate_prediction.tsv"
  if [ -f "${TSV_FILE}" ]; then
    tail -n +2 "${TSV_FILE}" | awk -v mag="${MAG}" 'BEGIN{OFS="\t"} {print mag, $0}' >> "${PUL_OUT}"
    echo "Processed: ${MAG}"
  else
    echo "Warning: File not found for ${MAG}"
  fi
done < "${NC_MAGS}"
