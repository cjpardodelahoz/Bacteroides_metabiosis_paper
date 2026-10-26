#!/bin/bash

#SBATCH --array=1-2045%300          # update upper bound to match isabl1_dbcan_successful_samples.txt rows
#SBATCH --mem=2G                    # Memory per task
#SBATCH -c 1                        # Number of CPU cores per task
#SBATCH --time=00:10:00             # Maximum runtime
#SBATCH --error=log/slurm/metagenome_sample_features_%A_%a.err
#SBATCH --output=log/slurm/metagenome_sample_features_%A_%a.out
#SBATCH --partition=cpu

mkdir -p log/slurm

# Set paths
SAMPLE_LIST="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
if [[ -z "${SAMPLE}" ]]; then
  echo "No sample entry for task ${SLURM_ARRAY_TASK_ID}; exiting"
  exit 0
fi
ABUND_DIR="analyses/bacteroides_pul/metagenome_pul_abund/${SAMPLE}"
PRED_DIR="analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/${SAMPLE}"
OUT_DIR="analyses/bacteroides_pul/metagenome_features/per_sample"
DEPTH="${ABUND_DIR}/${SAMPLE}.depth.txt"
SUBSTRATE="${ABUND_DIR}/fam_substrate_abund.out"
SIGNALP="${PRED_DIR}/signalp/prediction_results.txt"
CGC="${PRED_DIR}/cgc_standard_out.tsv"

mkdir -p "${OUT_DIR}"

# Step 1: Check inputs
for f in "${DEPTH}" "${SUBSTRATE}" "${SIGNALP}" "${CGC}"; do
  [ -s "${f}" ] || { echo "Missing or empty input for ${SAMPLE}: ${f}" >&2; exit 1; }
done

# Step 2: Sum gene TPM, raw read counts, and gene counts over digestive CGC genes
# Depth columns are gene, length, aligned read count; TPM = (col3/col2) / sum(col3/col2) * 1e6.
# Digestive features count each distinct GH/PL/CE family on a gene once; substrate
# features use dbcan_utils gene lists restricted to secreted digestive CGC genes.
awk -F'\t' -v sample="${SAMPLE}" '
FNR==1 { fi++ }
fi==1 { if ($2 > 0) { rate[$1]=$3/$2; cnt[$1]=$3; S+=rate[$1]; R+=$3; ng++ } next }
fi==2 { if (FNR>2 && $2!="OTHER") { split($1,a,"|"); sp[a[3]]=1 } next }
fi==3 { if (FNR>1 && ($1=="host glycan" || $1=="pectin")) { n=split($3,g,";"); for (i=1;i<=n;i++) subs[$1 SUBSEP g[i]]=1 } next }
fi==4 {
    if (FNR==1) next
    pid=$4
    if (pid in done) next
    done[pid]=1
    n=0; s=$8; delete seen
    while (match(s,/(GH|PL|CE)[0-9]+/)) {
        f=substr(s,RSTART,RLENGTH)
        if (!(f in seen)) { seen[f]=1; n++ }
        s=substr(s,RSTART+RLENGTH)
    }
    if (n==0) next
    nd++
    if (!(pid in rate)) { nmiss++; next }
    t=rate[pid]/S*1e6
    c=cnt[pid]
    dig+=t*n; rdig+=c*n
    if (pid in sp) {
        nsec++; sec+=t*n; rsec+=c*n
        if (("host glycan" SUBSEP pid) in subs) { host+=t; rhost+=c; nhost++ }
        if (("pectin" SUBSEP pid) in subs) { pec+=t; rpec+=c; npec++ }
    }
}
END {
    printf "%s\t%.6f\t%.6f\t%.6f\t%.6f\t%d\t%d\t%d\t%d\t%d\t%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\n", sample, dig, sec, host, pec, nd, nsec, nhost, npec, ng, nmiss, rdig, rsec, rhost, rpec, R
}' "${DEPTH}" "${SIGNALP}" "${SUBSTRATE}" "${CGC}" > "${OUT_DIR}/${SAMPLE}.tsv.tmp" \
  && mv "${OUT_DIR}/${SAMPLE}.tsv.tmp" "${OUT_DIR}/${SAMPLE}.tsv"
