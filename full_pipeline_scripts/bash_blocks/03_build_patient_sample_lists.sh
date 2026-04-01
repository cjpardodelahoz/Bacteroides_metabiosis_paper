#!/usr/bin/env bash
set -euo pipefail

# Build patient sample lists for VAMB
# Groups successful samples by PatientID from read_metadata.csv
# Creates one file per patient: analyses/bacteroides_pul/binning/short/isabl1/patient_samples/{PatientID}.txt
# Each file contains one SampleID per line

mkdir -p analyses/bacteroides_pul/binning/short/isabl1/patient_samples

awk -F',' 'NR>1 {gsub(/\r/,"",$2); gsub(/\r/,"",$3); print $3"\t"$2}' data/read_metadata.csv \
  | while IFS=$'\t' read -r patient sample; do
      grep -qx "$sample" analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt || continue
      echo "$sample" >> "analyses/bacteroides_pul/binning/short/isabl1/patient_samples/${patient}.txt"
    done

echo "Successfully created patient sample lists in: analyses/bacteroides_pul/binning/short/isabl1/patient_samples/"
