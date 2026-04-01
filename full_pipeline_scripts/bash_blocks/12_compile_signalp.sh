#!/usr/bin/env bash
set -euo pipefail

NC_MAGS="analyses/bacteroides_pul/isabl1_nc_mags.txt"
SIG_OUT="analyses/bacteroides_pul/mag_pul_summary/compiled_signalp.tsv"

FIRST_MAG=$(head -n 1 "${NC_MAGS}")
FIRST_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${FIRST_MAG}/signalp/prediction_results.txt"

echo -e "mag\t$(sed -n '2p' "${FIRST_FILE}")" > "${SIG_OUT}"

while IFS= read -r MAG; do
  TSV_FILE="analyses/bacteroides_pul/mag_pul_prediction/isabl1/${MAG}/signalp/prediction_results.txt"
  if [ -f "${TSV_FILE}" ]; then
    tail -n +3 "${TSV_FILE}" | awk -v mag="${MAG}" 'BEGIN{OFS="\t"} {print mag, $0}' >> "${SIG_OUT}"
    echo "Processed: ${MAG}"
  else
    echo "Warning: File not found for ${MAG}"
  fi
done < "${NC_MAGS}"
