#!/usr/bin/env bash
set -euo pipefail

# List the bacterial reference genome accessions of PICRUSt2 (bac_ref) from the
# metadata shipped with the installed package (PICRUSt2 2.6.3, conda env picrust2)
# Output: analyses/picrust_custom_traits/bacteria_genomes.txt (26,868 accessions)

mkdir -p analyses/picrust_custom_traits

PICRUST_DEFAULTS=$(conda run -n picrust2 python -c "import os, picrust2; print(os.path.join(os.path.dirname(picrust2.__file__), 'default_files'))")
zcat "${PICRUST_DEFAULTS}/bacteria/bacteria_metadata.csv.gz" | awk -F',' 'NR>1{print $1}' \
  > analyses/picrust_custom_traits/bacteria_genomes.txt

echo "Reference genomes: $(wc -l < analyses/picrust_custom_traits/bacteria_genomes.txt)"
echo "Successfully created: analyses/picrust_custom_traits/bacteria_genomes.txt"
