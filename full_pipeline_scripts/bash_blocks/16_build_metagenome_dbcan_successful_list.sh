#!/usr/bin/env bash
set -euo pipefail

# List metagenomes where dbCAN produced CGC proteins (non-empty CGC.faa)
# Output: analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt

PRED_DIR="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1"
SAMPLE_LIST="analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt"
OUT="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt"

while IFS= read -r SAMPLE; do
  if [ -s "${PRED_DIR}/${SAMPLE}/CGC.faa" ]; then
    echo "${SAMPLE}"
  else
    echo "Warning: no CGC proteins for ${SAMPLE}" >&2
  fi
done < "${SAMPLE_LIST}" > "${OUT}"

echo "Successful samples: $(wc -l < "${OUT}") of $(wc -l < "${SAMPLE_LIST}")"
echo "Successfully created: ${OUT}"
