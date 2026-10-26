#!/bin/bash

#SBATCH --mem=8G                    # Memory
#SBATCH -c 4                        # Number of CPU cores
#SBATCH --time=24:00:00             # Maximum runtime
#SBATCH --error=log/slurm/download_picrust_reference_genomes_%j.err
#SBATCH --output=log/slurm/download_picrust_reference_genomes_%j.out
#SBATCH --partition=cpu

mkdir -p log/slurm

# Set paths
GENOME_LIST="analyses/picrust_custom_traits/bacteria_genomes.txt"
DOWNLOAD_DIR="analyses/picrust_custom_traits/gtdb_download"
TARBALL="${DOWNLOAD_DIR}/gtdb_genomes_reps_r214.tar.gz"
EXTRACT_DIR="${DOWNLOAD_DIR}/gtdb_genomes_reps_r214"
FLAT_DIR="${DOWNLOAD_DIR}/gtdb_genomes"
BAC_DIR="analyses/picrust_custom_traits/bacteria_genomes"

mkdir -p "${DOWNLOAD_DIR}" "${BAC_DIR}"

# Step 1: Download GTDB r214.1 representative genomes (all domains, ~75 GB).
# PICRUSt2 bac_ref tips are a subset of these accessions
# (https://github.com/picrust/picrust2/wiki/Creating-a-custom-trait-table)
wget -c -O "${TARBALL}" \
  https://data.gtdb.ecogenomic.org/releases/release214/214.1/genomic_files_reps/gtdb_genomes_reps_r214.tar.gz

# Step 2: Extract into a flat directory of {accession}_genomic.fna.gz files
tar -xf "${TARBALL}" -C "${DOWNLOAD_DIR}"
mkdir -p "${FLAT_DIR}"
find "${EXTRACT_DIR}" -type f -name '*_genomic.fna.gz' -print0 | xargs -0 -I{} mv {} "${FLAT_DIR}/"

# Step 3: Keep only the bacterial genomes of PICRUSt2 bac_ref
while IFS= read -r ACC; do
  mv "${FLAT_DIR}/${ACC}_genomic.fna.gz" "${BAC_DIR}/" 2>/dev/null || echo "Warning: genome not found for ${ACC}" >&2
done < "${GENOME_LIST}"

echo "Bacterial genomes kept: $(ls "${BAC_DIR}" | wc -l) (expected $(wc -l < "${GENOME_LIST}"))"

# Step 4: Remove the full GTDB download
rm -rf "${TARBALL}" "${EXTRACT_DIR}" "${FLAT_DIR}"
