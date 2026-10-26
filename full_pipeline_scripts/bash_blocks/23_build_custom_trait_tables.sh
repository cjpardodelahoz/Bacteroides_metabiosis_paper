#!/usr/bin/env bash
set -euo pipefail

# Build the custom PICRUSt2 trait tables from the reference genome dbCAN + SignalP outputs
# (one row per bac_ref genome, one column per <CAZy family>_<EC> trait) and copy the
# dbCAN family + EC -> substrate mapping used downstream.
# Outputs:
#   - analyses/picrust_custom_traits/custom_trait_table_secreted.tsv (signal-peptide-positive digestive CAZymes)
#   - analyses/picrust_custom_traits/custom_trait_table_all_digestive.tsv (all digestive CAZymes, same columns)
#   - analyses/picrust_custom_traits/dbcan_fam-substrate-mapping.tsv

GENOME_LIST="analyses/picrust_custom_traits/bacteria_genomes.txt"
SECRETED="analyses/picrust_custom_traits/custom_trait_table_secreted.tsv"
ALL_DIGESTIVE="analyses/picrust_custom_traits/custom_trait_table_all_digestive.tsv"
DB_DIR="/data1/xavierj/carlos/dbs/dbcan"

python3 full_pipeline_scripts/build_custom_trait_table.py "${GENOME_LIST}" "${SECRETED}" secreted
python3 full_pipeline_scripts/build_custom_trait_table.py "${GENOME_LIST}" "${ALL_DIGESTIVE}" all_digestive "${SECRETED}"

cp "${DB_DIR}/fam-substrate-mapping.tsv" analyses/picrust_custom_traits/dbcan_fam-substrate-mapping.tsv

echo "Successfully created: ${SECRETED}, ${ALL_DIGESTIVE}"
