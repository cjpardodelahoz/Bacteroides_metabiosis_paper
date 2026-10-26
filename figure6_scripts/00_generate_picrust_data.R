#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# Figure 6D / Figure S6 data-prep script
#
# Purpose:
# Stage the PICRUSt2 custom-trait predictions, the dbCAN substrate mapping, and
# the per-sample metagenome features used by Figure 6D and Figure S6 into
# data/figure6/ and data/figureS6/.
#
# Upstream inputs come from full-pipeline sections E (metagenome features) and
# F (PICRUSt2 custom traits). The quickstart does not need this script; its
# outputs are provided in the data download.
#
# Design notes:
# - The frozen Figure 1E matched design (data/figure6/fig1e_matched_sets.csv,
#   data/figure6/fig1e_history_samples.csv) and the ASV taxonomy
#   (data/taxonomy.csv) are distributed inputs and are not rebuilt here.
# - ASV read counts are not exported: downstream scripts read them from
#   data/Liao_etal_2021/tblcounts_asv_wide.csv.
#
# Inputs:
# - analyses/picrust_custom_traits/hsp/cazy_custom_predicted_{secreted,all_digestive}.tsv.gz
# - analyses/picrust_custom_traits/placement/marker_predicted_and_nsti.tsv.gz
# - analyses/picrust_custom_traits/dbcan_fam-substrate-mapping.tsv
# - analyses/bacteroides_pul/metagenome_features/metagenome_sample_features.tsv
#
# Outputs:
# - data/figure6/picrust_marker_nsti.tsv.gz
# - data/figure6/picrust_cazyme_secreted.tsv.gz
# - data/figure6/picrust_cazyme_all_digestive.tsv.gz
# - data/figure6/dbcan_fam-substrate-mapping-08012023.tsv
# - data/figureS6/metagenome_sample_features.tsv
# -----------------------------------------------------------------------------

PICRUST_DIR <- "analyses/picrust_custom_traits"

dir.create("data/figure6", showWarnings = FALSE, recursive = TRUE)
dir.create("data/figureS6", showWarnings = FALSE, recursive = TRUE)

copy_input <- function(from, to) {
  if (!file.exists(from)) stop("Missing input: ", from)
  stopifnot(file.copy(from, to, overwrite = TRUE))
  message("Saved: ", to)
}

# -----------------------------------------------------------------------------
# 1) PICRUSt2 outputs and dbCAN substrate mapping (Figure 6D, S6A, S6B)
# -----------------------------------------------------------------------------

copy_input(file.path(PICRUST_DIR, "placement/marker_predicted_and_nsti.tsv.gz"),
           "data/figure6/picrust_marker_nsti.tsv.gz")
copy_input(file.path(PICRUST_DIR, "hsp/cazy_custom_predicted_secreted.tsv.gz"),
           "data/figure6/picrust_cazyme_secreted.tsv.gz")
copy_input(file.path(PICRUST_DIR, "hsp/cazy_custom_predicted_all_digestive.tsv.gz"),
           "data/figure6/picrust_cazyme_all_digestive.tsv.gz")
copy_input(file.path(PICRUST_DIR, "dbcan_fam-substrate-mapping.tsv"),
           "data/figure6/dbcan_fam-substrate-mapping-08012023.tsv")

# -----------------------------------------------------------------------------
# 2) Per-sample metagenome features (Figure S6B)
# -----------------------------------------------------------------------------

copy_input("analyses/bacteroides_pul/metagenome_features/metagenome_sample_features.tsv",
           "data/figureS6/metagenome_sample_features.tsv")
