#!/usr/bin/env bash
set -euo pipefail

# Compile dbCAN-sub (eCAMI subfamily) high-level substrate annotations across
# all filtered MAGs into one table keyed on MAG + protein.

NC_MAGS="analyses/bacteroides_pul/isabl1_nc_mags.txt"
PRED_DIR="analyses/bacteroides_pul/mag_pul_prediction/isabl1"
OUT="analyses/bacteroides_pul/mag_pul_summary/compiled_dbcansub_substrates.tsv.gz"

mkdir -p analyses/bacteroides_pul/mag_pul_summary

{
  printf 'mag\tsubfam\tsubstrate\tprotein_id\n'
  while IFS= read -r MAG; do
    TSV="${PRED_DIR}/${MAG}/dbCANsub_hmm_results.tsv"
    if [ -f "${TSV}" ]; then
      # Columns: 1 = subfamily, 4 = substrate, 6 = protein ID
      awk -F'\t' -v mag="${MAG}" 'NR > 1 && NF >= 6 { print mag "\t" $1 "\t" $4 "\t" $6 }' "${TSV}"
    else
      echo "Warning: File not found for ${MAG}" >&2
    fi
  done < "${NC_MAGS}"
} | gzip -c > "${OUT}"

echo "Wrote ${OUT}"
