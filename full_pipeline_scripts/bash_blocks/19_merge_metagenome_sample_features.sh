#!/usr/bin/env bash
set -euo pipefail

# Merge per-sample metagenome features into one table
# Output: analyses/bacteroides_pul/metagenome_features/metagenome_sample_features.tsv

SAMPLE_LIST="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt"
OUT_DIR="analyses/bacteroides_pul/metagenome_features"
PER_SAMPLE="${OUT_DIR}/per_sample"
MERGED="${OUT_DIR}/metagenome_sample_features.tsv"

printf 'SampleID\tmetagenome_digestive_tpm\tmetagenome_secreted_tpm\tmetagenome_host_glycan_tpm\tmetagenome_pectin_tpm\tn_digestive_genes\tn_secreted_genes\tn_host_glycan_genes\tn_pectin_genes\tn_depth_genes\tn_cgc_genes_missing_depth\tmetagenome_digestive_reads\tmetagenome_secreted_reads\tmetagenome_host_glycan_reads\tmetagenome_pectin_reads\ttotal_aligned_reads\n' > "${MERGED}"
cat "${PER_SAMPLE}"/*.tsv >> "${MERGED}"

echo "Expected samples: $(wc -l < "${SAMPLE_LIST}")"
echo "Merged rows: $(($(wc -l < "${MERGED}") - 1))"
echo "Samples without output:"
comm -23 <(sort "${SAMPLE_LIST}") <(cut -f1 "${MERGED}" | tail -n +2 | sort)
echo "Successfully created: ${MERGED}"
