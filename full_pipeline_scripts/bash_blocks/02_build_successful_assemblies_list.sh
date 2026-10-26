#!/usr/bin/env bash
set -euo pipefail

# Build list of successful assemblies from metaSPAdes output
# Only samples in the final accession manifest are eligible.
# Output: analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt

Rscript - <<'RS'
metadata <- read.csv("data/read_metadata.csv", colClasses = "character")
stopifnot(!anyNA(metadata$SampleID), all(nzchar(metadata$SampleID)),
          !anyDuplicated(metadata$SampleID))
assemblies <- file.path("analyses/bacteroides_pul/metagenomes/assembly/metaspades",
                        metadata$SampleID, "contigs.fasta")
writeLines(sort(metadata$SampleID[file.exists(assemblies)]),
           "analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt")
RS

echo "Successfully created: analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt"
