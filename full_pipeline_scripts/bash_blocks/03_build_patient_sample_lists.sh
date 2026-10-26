#!/usr/bin/env bash
set -euo pipefail

# Build patient sample lists for VAMB
# Groups successful samples by PatientID from read_metadata.csv
# Creates one file per patient: analyses/bacteroides_pul/binning/short/isabl1/patient_samples/{PatientID}.txt
# Each file contains one SampleID per line

mkdir -p analyses/bacteroides_pul/binning/short/isabl1/patient_samples

Rscript - <<'RS'
metadata <- read.csv("data/read_metadata.csv", colClasses = "character")
stopifnot(!anyDuplicated(metadata$SampleID), !anyNA(metadata$PatientID),
          all(nzchar(metadata$PatientID)))
successful <- readLines("analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt")
stopifnot(all(successful %in% metadata$SampleID))
metadata <- metadata[metadata$SampleID %in% successful, ]
directory <- "analyses/bacteroides_pul/binning/short/isabl1/patient_samples"
unlink(list.files(directory, pattern = "[.]txt$", full.names = TRUE))
for (patient in unique(metadata$PatientID)) {
  writeLines(metadata$SampleID[metadata$PatientID == patient],
             file.path(directory, paste0(patient, ".txt")))
}
RS

echo "Successfully created patient sample lists in: analyses/bacteroides_pul/binning/short/isabl1/patient_samples/"
