#!/usr/bin/env bash
set -euo pipefail

# Build list of successful assemblies from metaSPAdes output
# This scans the assembly directory and extracts all SampleIDs that produced contigs.fasta
# Output: analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt

find analyses/bacteroides_pul/metagenomes/assembly/metaspades -type f -name contigs.fasta \
  | awk -F'/' '{print $6}' | sort > analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt

echo "Successfully created: analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt"
