#!/usr/bin/env bash
set -euo pipefail

mkdir -p data/gtdb

curl -o data/gtdb/bac120_r226.tree \
  https://data.ace.uq.edu.au/public/gtdb/data/releases/release226/226.0/bac120_r226.tree

curl -o data/gtdb/bac120_taxonomy_r226.tsv \
  https://data.ace.uq.edu.au/public/gtdb/data/releases/release226/226.0/bac120_taxonomy_r226.tsv

curl -o data/gtdb/bac120_metadata_r226.tsv.gz \
  https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/bac120_metadata.tsv.gz
