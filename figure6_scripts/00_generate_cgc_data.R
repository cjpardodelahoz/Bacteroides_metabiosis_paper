#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# Figure 6 data-prep script
#
# Purpose:
# Build a gene-level CGC table used by downstream Figure 6 plotting scripts.
#
# Design notes:
# - Adds boolean flags to explicitly distinguish:
#     * has_signalp_cgc  : CGC contains >=1 digestive CAZyme with signal peptide
#     * has_signalp_gene : gene is one of those signal-peptide digestive CAZymes
# - Writes a single publication-ready table to data/figure6/cgc_data.csv.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
})

# -----------------------------------------------------------------------------
# 1) Load core inputs (compiled dbCAN CGCs, SignalP, taxonomy/QC, substrates)
# -----------------------------------------------------------------------------

message("Loading inputs...")
# Compiled dbCAN CGC table (one row per predicted gene in a CGC)
compiled_cgc <- fread("analyses/bacteroides_pul/mag_pul_summary/compiled_cgcs.tsv")
# Compiled SignalP calls parsed into MAG, CGC and protein identifiers
compiled_signalp <- fread("analyses/bacteroides_pul/mag_pul_summary/compiled_signalp.tsv") %>%
  separate(`# ID`, into = c("temp", "cgc", "protein_id"), sep = "\\|", remove = TRUE, extra = "drop") %>%
  select(mag, cgc, protein_id, Prediction)

# GTDB taxonomy summary for recovered MAGs
gtdb <- read_delim("analyses/bacteroides_pul/gtdb/gtdbtk.bac120.summary.tsv", show_col_types = FALSE)
# CheckM2 quality report for recovered MAGs
checkm <- read_delim("analyses/bacteroides_pul/checkm2/quality_report.tsv", show_col_types = FALSE)

# Integrated taxonomy + assembly quality table used across downstream joins
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
    # Harmonize Prevotella-like genus names to match manuscript taxonomy usage
    family = case_when(
      str_detect(genus, "revotella") ~ "Prevotellaceae",
      TRUE ~ family
    )
  )

# Compiled substrate predictions at MAG/CGC level from dbCAN output
compiled_puls <- read_delim("analyses/bacteroides_pul/mag_pul_summary/compiled_puls.tsv", show_col_types = FALSE) %>%
  mutate(
    # Match CGC identifier format used in compiled_cgc
    `CGC#` = str_remove(`#cgcid`, ".*\\|"),
    # Keep the same substrate precedence used in the original qmd analysis
    substrate = case_when(
      is.na(`dbCAN-PUL substrate`) & !is.na(`dbCAN-sub substrate`) ~ `dbCAN-sub substrate`,
      TRUE ~ `dbCAN-PUL substrate`
    )
  ) %>%
  # Keep one substrate annotation per row; multi-substrate labels are excluded
  filter(!str_detect(substrate, ",")) %>%
  select(mag, `CGC#`, substrate)

# MAG universe used for tree-based comparisons in the original analysis
nc_mags <- full_report %>%
  filter(Contamination <= 10, Completeness >= 90, Contig_N50 >= 50000) %>%
  pull(user_genome) %>%
  unique()

# -----------------------------------------------------------------------------
# 2) Recreate digestive-CAZyme + SignalP filtering logic from the qmd
# -----------------------------------------------------------------------------

message("Deriving digestive CAZyme + signal peptide CGCs...")

# Robust parser for dbCAN gene annotation fields to extract catalytic subfamily.
# Mirrors the original handling of mixed annotation formats.
extract_subfam <- function(x) {
  if (str_count(x, "\\|") == 1) {
    return(str_split_i(x, "\\|", 2))
  }
  if (str_detect(x, "GH|PL|CE")) {
    fields <- str_split(x, "\\|", simplify = TRUE)
    target_field <- fields[str_detect(fields, "GH|PL|CE")][1]
    return(str_remove(target_field, "\\+.*$"))
  }
  str_remove(x, "^[^|]*\\|")
}

cazyme_data <- compiled_cgc %>%
  filter(mag %in% nc_mags) %>%
  # Remove CGCs containing GT genes (focus on digestive catabolic potential)
  group_by(mag, `CGC#`) %>%
  filter(!any(str_detect(`Gene Annotation`, "GT"))) %>%
  ungroup() %>%
  filter(`Gene Type` == "CAZyme") %>%
  mutate(
    cazy_subfam = vapply(`Gene Annotation`, extract_subfam, character(1)),
    cazy_fam = str_remove(cazy_subfam, "_.*"),
    cazy_type = str_extract(cazy_fam, "GH|PL|CE")
  ) %>%
  # Keep only catabolic CAZyme classes used in the manuscript (GH/PL/CE)
  filter(str_detect(cazy_subfam, "GH|PL|CE")) %>%
  left_join(select(compiled_signalp, mag, protein_id, Prediction), by = c("Protein ID" = "protein_id", "mag")) %>%
  left_join(
    select(
      full_report,
      user_genome,
      domain, phylum, class, order, family, genus, species,
      Completeness, Contamination, Contig_N50, Genome_Size
    ),
    by = c("mag" = "user_genome")
  )

# cazyme_data = digestive CAZyme-only table with SignalP calls and MAG metadata

# CGCs considered signal-positive for Figure 6A logic
cgcs_with_signalp <- cazyme_data %>%
  filter(Prediction != "OTHER") %>%
  distinct(mag, `CGC#`)

# -----------------------------------------------------------------------------
# 3) Build final gene-level table with explicit signalp flags and annotations
# -----------------------------------------------------------------------------

message("Building final cgc_data table...")
# Final publication table at gene resolution, preserving all nc_mags
cgc_data_filtered <- compiled_cgc %>%
  # Preserve all nc_mags, including those with zero signal-positive CGCs
  filter(mag %in% nc_mags) %>%
  # CGC-level flag: this CGC contains >=1 signal-positive digestive CAZyme
  left_join(cgcs_with_signalp %>% mutate(has_signalp_cgc = TRUE), by = c("mag", "CGC#")) %>%
  mutate(has_signalp_cgc = replace_na(has_signalp_cgc, FALSE)) %>%
  # Gene-level flag: this exact gene is a signal-positive digestive CAZyme
  left_join(
    cazyme_data %>%
      filter(Prediction != "OTHER") %>%
      distinct(mag, `CGC#`, `Protein ID`) %>%
      mutate(has_signalp_gene = TRUE),
    by = c("mag", "CGC#", "Protein ID")
  ) %>%
  mutate(
    has_signalp_gene = replace_na(has_signalp_gene, FALSE),
    # Convenience CAZyme class column used by downstream plot scripts
    cazy_type = case_when(
      `Gene Type` == "CAZyme" & str_detect(`Gene Annotation`, "GH") ~ "GH",
      `Gene Type` == "CAZyme" & str_detect(`Gene Annotation`, "PL") ~ "PL",
      `Gene Type` == "CAZyme" & str_detect(`Gene Annotation`, "CE") ~ "CE",
      TRUE ~ NA_character_
    )
  ) %>%
  left_join(
    select(
      full_report,
      user_genome,
      domain, phylum, class, order, family, genus, species,
      Completeness, Contamination, Contig_N50, Genome_Size
    ),
    by = c("mag" = "user_genome")
  ) %>%
  left_join(compiled_puls, by = c("mag", "CGC#")) %>%
  rename(`Predicted substrate` = substrate) %>%
  select(
    mag,
    `CGC#`,
    `Gene Type`,
    `Gene Annotation`,
    `Contig ID`,
    `Gene Start`,
    `Gene Stop`,
    `Gene Strand`,
    cazy_type,
    has_signalp_cgc,
    has_signalp_gene,
    domain, phylum, class, order, family, genus, species,
    Completeness, Contamination, Contig_N50, Genome_Size,
    `Predicted substrate`
  ) %>%
  rename(
    `Mag` = mag,
    `Cgc#` = `CGC#`,
    `Gene type` = `Gene Type`,
    `Gene annotation` = `Gene Annotation`,
    `Contig id` = `Contig ID`,
    `Gene start` = `Gene Start`,
    `Gene stop` = `Gene Stop`,
    `Gene strand` = `Gene Strand`,
    `Cazy type` = cazy_type,
    `Has signalp cgc` = has_signalp_cgc,
    `Has signalp gene` = has_signalp_gene,
    `Domain` = domain,
    `Phylum` = phylum,
    `Class` = class,
    `Order` = order,
    `Family` = family,
    `Genus` = genus,
    `Species` = species,
    `Contig n50` = Contig_N50,
    `Genome size` = Genome_Size
  )

# -----------------------------------------------------------------------------
# 4) Diagnostics and write output
# -----------------------------------------------------------------------------

message(sprintf("MAGs in nc_mags universe: %d", length(unique(nc_mags))))
message(sprintf("MAGs represented in cgc_data.csv: %d", n_distinct(cgc_data_filtered$`Mag`)))
message(sprintf("MAGs with >=1 signalp digestive CGC: %d", n_distinct(cgc_data_filtered$`Mag`[cgc_data_filtered$`Has signalp cgc`])))

if (!dir.exists("data/figure6")) {
  dir.create("data/figure6", recursive = TRUE)
}

write_csv(cgc_data_filtered, "data/figure6/cgc_data.csv")
message("Saved: data/figure6/cgc_data.csv")
