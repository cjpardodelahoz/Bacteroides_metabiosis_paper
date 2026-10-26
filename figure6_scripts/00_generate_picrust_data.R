#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# Figure 6D / Figure S6 data-prep script
#
# Purpose:
# Stage the PICRUSt2 custom-trait inputs used by Figure 6D and Figure S6 into
# data/figure6/ and data/figureS6/, and build a single ASV taxonomy table.
#
# Provenance only: the `analyses/picrust_custom_traits/` inputs come from the
# PICRUSt2 custom-trait workflow and are not distributed with this repository.
# The quickstart does not need this script; its outputs are provided in the
# data download.
#
# Design notes:
# - asv_taxonomy.csv merges two sources into one table (one row per Liao ASV):
#     * Phylum, Genus: the original Figure 1E assignments (used by Fig6D/S6).
#       ASVs outside the Figure 1E set have no Phylum/Genus.
#     * Family: Liao et al. 2021 SILVA 132 assignments (used by Fig6C).
# - ASV read counts are not exported: downstream scripts read them from
#   data/Liao_etal_2021/tblcounts_asv_wide.csv.
#
# Inputs:
# - analyses/picrust_custom_traits/liao_rerun/cazy_custom_predicted.tsv.gz
# - analyses/picrust_custom_traits/liao_rerun_all_digestive/cazy_custom_predicted_all_digestive.tsv.gz
# - analyses/picrust_custom_traits/reference/predictions/marker_predicted_and_nsti.tsv.gz
# - analyses/picrust_custom_traits/reference/figure1E_minimal/data/{taxonomy,matched_sets,history_samples}.csv
# - analyses/picrust_custom_traits/reference/mappings/reference/dbcan_fam-substrate-mapping-08012023.tsv
# - analyses/picrust_custom_traits/metagenome_validation/metagenome_sample_features.tsv
# - data/Liao_etal_2021/tblASVtaxonomy_silva132_v4v5_filter.csv
#
# Outputs:
# - data/figure6/asv_taxonomy.csv
# - data/figure6/picrust_marker_nsti.tsv.gz
# - data/figure6/picrust_cazyme_secreted.tsv.gz
# - data/figure6/picrust_cazyme_all_digestive.tsv.gz
# - data/figure6/fig1e_matched_sets.csv
# - data/figure6/fig1e_history_samples.csv
# - data/figure6/dbcan_fam-substrate-mapping-08012023.tsv
# - data/figureS6/metagenome_sample_features.tsv
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
})

PICRUST_DIR <- "analyses/picrust_custom_traits"
REF_DIR <- file.path(PICRUST_DIR, "reference")
FIG1E_DIR <- file.path(REF_DIR, "figure1E_minimal/data")

dir.create("data/figure6", showWarnings = FALSE, recursive = TRUE)
dir.create("data/figureS6", showWarnings = FALSE, recursive = TRUE)

copy_input <- function(from, to) {
  if (!file.exists(from)) stop("Missing input: ", from)
  stopifnot(file.copy(from, to, overwrite = TRUE))
  message("Saved: ", to)
}

# -----------------------------------------------------------------------------
# 1) Merged ASV taxonomy
# -----------------------------------------------------------------------------

message("Building merged ASV taxonomy...")
fig1e_tax <- fread(file.path(FIG1E_DIR, "taxonomy.csv"), colClasses = c(ASV = "character"))
silva_tax <- fread("data/Liao_etal_2021/tblASVtaxonomy_silva132_v4v5_filter.csv",
                   select = c("ASV", "Family"), colClasses = c(ASV = "character"))
stopifnot(!anyDuplicated(fig1e_tax$ASV), !anyDuplicated(silva_tax$ASV),
          all(fig1e_tax$ASV %chin% silva_tax$ASV))

asv_taxonomy <- merge(silva_tax, fig1e_tax[, .(ASV, Phylum, Genus)], by = "ASV", all.x = TRUE)
asv_taxonomy <- asv_taxonomy[order(as.integer(sub("^ASV_", "", ASV))), .(ASV, Phylum, Genus, Family)]
fwrite(asv_taxonomy, "data/figure6/asv_taxonomy.csv")
message(sprintf("Saved: data/figure6/asv_taxonomy.csv (%d ASVs, %d with Figure 1E Phylum/Genus)",
                nrow(asv_taxonomy), asv_taxonomy[!is.na(Phylum), .N]))

# -----------------------------------------------------------------------------
# 2) PICRUSt2 outputs, frozen Figure 1E design, and substrate mappings
# -----------------------------------------------------------------------------

copy_input(file.path(REF_DIR, "predictions/marker_predicted_and_nsti.tsv.gz"),
           "data/figure6/picrust_marker_nsti.tsv.gz")
copy_input(file.path(PICRUST_DIR, "liao_rerun/cazy_custom_predicted.tsv.gz"),
           "data/figure6/picrust_cazyme_secreted.tsv.gz")
copy_input(file.path(PICRUST_DIR, "liao_rerun_all_digestive/cazy_custom_predicted_all_digestive.tsv.gz"),
           "data/figure6/picrust_cazyme_all_digestive.tsv.gz")
copy_input(file.path(FIG1E_DIR, "matched_sets.csv"), "data/figure6/fig1e_matched_sets.csv")
copy_input(file.path(FIG1E_DIR, "history_samples.csv"), "data/figure6/fig1e_history_samples.csv")
copy_input(file.path(REF_DIR, "mappings/reference/dbcan_fam-substrate-mapping-08012023.tsv"),
           "data/figure6/dbcan_fam-substrate-mapping-08012023.tsv")

# -----------------------------------------------------------------------------
# 3) Per-sample metagenome features (Figure S6B)
# -----------------------------------------------------------------------------

copy_input(file.path(PICRUST_DIR, "metagenome_validation/metagenome_sample_features.tsv"),
           "data/figureS6/metagenome_sample_features.tsv")
