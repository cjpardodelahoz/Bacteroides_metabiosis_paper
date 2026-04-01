#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

checkm_path <- "analyses/bacteroides_pul/checkm2/quality_report.tsv"
gtdb_path <- "analyses/bacteroides_pul/gtdb/gtdbtk.bac120.summary.tsv"
out_dir <- "analyses/bacteroides_pul/mag_pul_summary"
out_full_report <- file.path(out_dir, "mag_qc_taxonomy_summary.tsv")
out_nc_mags <- "analyses/bacteroides_pul/isabl1_nc_mags.txt"

if (!file.exists(checkm_path)) {
  stop("Missing CheckM2 report: ", checkm_path)
}
if (!file.exists(gtdb_path)) {
  stop("Missing GTDB summary: ", gtdb_path)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

gtdb <- read_delim(gtdb_path, show_col_types = FALSE)
checkm <- read_delim(checkm_path, show_col_types = FALSE)

full_report <- left_join(gtdb, checkm, by = c("user_genome" = "Name")) %>%
  separate(
    classification,
    into = c("domain", "phylum", "class", "order", "family", "genus", "species"),
    sep = ";",
    fill = "right",
    remove = FALSE
  ) %>%
  mutate(across(c(domain, phylum, class, order, family, genus, species), ~ sub("^[a-z]__", "", .))) %>%
  mutate(
    family = case_when(
      str_detect(genus, "revotella") ~ "Prevotellaceae",
      TRUE ~ family
    )
  )

nc_mags <- full_report %>%
  filter(Contamination <= 10, Completeness >= 90, Contig_N50 >= 50000) %>%
  pull(user_genome) %>%
  unique() %>%
  sort()

write_tsv(full_report, out_full_report)
write_lines(nc_mags, out_nc_mags)

message("Saved: ", out_full_report)
message("Saved: ", out_nc_mags)
message("NC MAGs: ", length(nc_mags))
