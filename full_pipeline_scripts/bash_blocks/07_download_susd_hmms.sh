#!/usr/bin/env bash
set -euo pipefail

mkdir -p hmms/susD

curl -o hmms/susD/PF07980.hmm.gz "https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF07980?annotation=hmm"
curl -o hmms/susD/PF12741.hmm.gz "https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF12741?annotation=hmm"
curl -o hmms/susD/PF12771.hmm.gz "https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF12771?annotation=hmm"
curl -o hmms/susD/PF14322.hmm.gz "https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF14322?annotation=hmm"

gunzip -f hmms/susD/*.hmm.gz
