#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# Figure 6 C/D data-prep script
#
# Purpose:
# Build the single sample-level input table used by:
# - 05_plot_bacteroidota_fam_abund.R (Fig6C)
# - 06_plot_linearmodels_auc.R       (Fig6D)
#
# Design notes:
# - Includes all patients (single and multi-transplant).
# - Handles multi-HCT patients by assigning each event/sample to the nearest
#   transplant and introducing a transplant episode identifier.
# - Uses a single quinolone-start definition shared by both downstream plots:
#   first quinolone day within DayRelativeToNearestHCT in [-10, 0].
# - Restricts output sample rows to days [-10, 30] relative to nearest HCT.
#
# Output:
# - data/figure6/bsi_model_input.csv
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

# -----------------------------------------------------------------------------
# 1) Create output directory
# -----------------------------------------------------------------------------

if (!dir.exists("data/figure6")) {
  dir.create("data/figure6", recursive = TRUE)
}

# -----------------------------------------------------------------------------
# 2) Helper functions
# -----------------------------------------------------------------------------

# For a patient/day, return the nearest transplant timepoint.
# This is used consistently for clinical events and microbiome samples.
get_nearest_hct_timepoint <- function(patient_id, event_day, hct_meta) {
  patient_hcts <- hct_meta %>%
    filter(PatientID == patient_id) %>%
    pull(TimepointOfTransplant)
  patient_hcts[which.min(abs(event_day - patient_hcts))]
}

# Extract selected taxa abundances from a wide count table.
# - file_path: path to wide count table (rows = taxa, columns = samples)
# - taxon_col: column containing taxon labels (e.g., Family, Phylum, ASV)
# - target_taxa: taxa to retain and convert to relative abundance
extract_selected_abundances <- function(file_path, taxon_col, target_taxa) {
  counts_wide <- suppressMessages(read_csv(file_path))
  sample_cols <- setdiff(names(counts_wide), taxon_col)

  # Ensure sample columns are numeric counts.
  counts_wide <- counts_wide %>%
    mutate(across(all_of(sample_cols), as.numeric))

  # Per-sample sequencing depth for relative abundance normalization.
  total_counts <- colSums(as.matrix(counts_wide[, sample_cols]), na.rm = TRUE)

  # Keep only requested taxa.
  selected_counts <- counts_wide %>%
    filter(.data[[taxon_col]] %in% target_taxa) %>%
    select(all_of(taxon_col), all_of(sample_cols))

  # Add explicit zero rows for target taxa absent from the source file.
  missing_taxa <- setdiff(target_taxa, selected_counts[[taxon_col]])
  if (length(missing_taxa) > 0) {
    zeros_tbl <- tibble(!!taxon_col := missing_taxa)
    for (col in sample_cols) {
      zeros_tbl[[col]] <- 0
    }
    selected_counts <- bind_rows(selected_counts, zeros_tbl)
  }

  selected_long <- selected_counts %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "SampleID",
      values_to = "count"
    )

  totals_tbl <- tibble(SampleID = sample_cols, total_count = as.numeric(total_counts))

  selected_abund <- selected_long %>%
    left_join(totals_tbl, by = "SampleID") %>%
    mutate(abundance = if_else(total_count > 0, count / total_count, 0)) %>%
    select(SampleID, !!sym(taxon_col), abundance) %>%
    pivot_wider(
      names_from = !!sym(taxon_col),
      values_from = abundance,
      names_glue = "{.value}_{.name}"
    ) %>%
    rename_with(~ str_replace(.x, "^abundance_", ""), starts_with("abundance_")) %>%
    rename_with(~ paste0(.x, "_abund"), -SampleID)

  selected_abund
}

# -----------------------------------------------------------------------------
# 3) Load core metadata and constants
# -----------------------------------------------------------------------------

message("Loading transplant metadata and constants...")

# Core transplant metadata table (potentially multiple rows per patient).
tblhctmeta <- suppressMessages(read_csv("data/Liao_etal_2021/tblhctmeta.csv"))
# Patient universe used throughout this script.
all_patients <- unique(tblhctmeta$PatientID)

# Antibiotic categories mirrored from the original clinical workflow.
antibiotics <- c(
  "glycopeptide antibiotics",
  "quinolones",
  "penicillins",
  "sulfonamides",
  "cephalosporins",
  "carbapenems"
)

# Proteobacteria-associated bloodstream infection agents used in this analysis.
proteobacteria_agents <- c(
  "Escherichia",
  "Klebsiella_Pneumoniae",
  "Enterobacter",
  "Citrobacter",
  "Klebsiella",
  "Pseudomonas",
  "Stenotrophomonas_Maltophilia"
)

# -----------------------------------------------------------------------------
# 4) Build episode-specific WBC status table
# -----------------------------------------------------------------------------

message("Deriving neutropenia/engraftment status by transplant episode...")

engraftment_threshold <- 3

# Episode-aware WBC status table with one row per lab measurement and inferred
# neutropenia/engraftment state labels.
tblwbc_status <- suppressMessages(read_csv("data/Liao_etal_2021/tblwbc.csv")) %>%
  filter(PatientID %in% all_patients, BloodCellType == "WBCtotal") %>%
  mutate(
    WBCtotal = as.numeric(str_replace(Value, "<0.1", "0")),
    NearestHCTTimepoint = mapply(
      get_nearest_hct_timepoint,
      PatientID,
      Timepoint,
      MoreArgs = list(hct_meta = tblhctmeta)
    ),
    DayRelativeToNearestHCT = Timepoint - NearestHCTTimepoint,
    TransplantEpisodeID = paste(PatientID, NearestHCTTimepoint, sep = "__")
  ) %>%
  group_by(PatientID, NearestHCTTimepoint, TransplantEpisodeID) %>%
  arrange(DayRelativeToNearestHCT, .by_group = TRUE) %>%
  mutate(
    Status = case_when(
      WBCtotal < 0.5 & cumall(lag(WBCtotal, default = Inf) >= 0.5) & row_number() > 1 ~ "NeutropeniaStart",
      WBCtotal < 0.5 ~ "Neutropenia",
      TRUE ~ NA_character_
    )
  ) %>%
  mutate(
    Status = case_when(
      WBCtotal >= 0.5 & (purrr::map_lgl(row_number(), ~ any(Status[(.x + 1):n()] == "NeutropeniaStart")) | all(is.na(Status))) ~ "PreNeutropenia",
      DayRelativeToNearestHCT > 0 & purrr::map_lgl(row_number(), ~ all(WBCtotal[max(1, (.x - engraftment_threshold)):.x] >= 0.5)) & lag(Status, (engraftment_threshold + 1), default = NA) %in% c("Neutropenia", "NeutropeniaStart") ~ "Engraftment",
      TRUE ~ Status
    )
  ) %>%
  mutate(
    Status = case_when(
      WBCtotal >= 0.5 & purrr::map_lgl(row_number(), ~ any(Status[1:(.x - 1)] == "Engraftment")) ~ "PostEngraftment",
      Status == "Neutropenia" & purrr::map_lgl(row_number(), ~ any(Status[1:(.x - 1)] == "Engraftment")) ~ "NeutropeniaPostEngraftment",
      WBCtotal >= 0.5 & purrr::map_lgl(row_number(), ~ any(Status[(.x + 1):(.x + engraftment_threshold)] == "Engraftment")) ~ "TransitionToEngraftment",
      TRUE ~ Status
    )
  ) %>%
  ungroup() %>%
  select(PatientID, NearestHCTTimepoint, TransplantEpisodeID, DayRelativeToNearestHCT, Status)

# -----------------------------------------------------------------------------
# 5) Build episode-specific quinolone start and infection cutoffs
# -----------------------------------------------------------------------------

message("Computing quinolone, infection, and engraftment cutoffs...")

# Expand antibiotic windows to one row per episode-day exposure.
# Result: episode-day antibiotic exposure matrix with binary category flags.
tbldrug_expanded <- suppressMessages(read_csv("data/Liao_etal_2021/tbldrug.csv")) %>%
  filter(Category %in% antibiotics, PatientID %in% all_patients) %>%
  mutate(
    NearestHCTTimepoint = mapply(
      get_nearest_hct_timepoint,
      PatientID,
      StartTimepoint,
      MoreArgs = list(hct_meta = tblhctmeta)
    ),
    TransplantEpisodeID = paste(PatientID, NearestHCTTimepoint, sep = "__")
  ) %>%
  rowwise() %>%
  mutate(DayRelativeToNearestHCT = list(StartDayRelativeToNearestHCT:StopDayRelativeToNearestHCT)) %>%
  unnest(DayRelativeToNearestHCT) %>%
  ungroup() %>%
  select(PatientID, NearestHCTTimepoint, TransplantEpisodeID, Category, DayRelativeToNearestHCT) %>%
  distinct() %>%
  mutate(flag = 1) %>%
  pivot_wider(names_from = Category, values_from = flag, values_fill = 0)

# Shared quinolone criterion for Fig6C and Fig6D.
# For each transplant episode, this marks the first prophylaxis day in [-10, 0].
first_quin_day <- tbldrug_expanded %>%
  filter(quinolones == 1, between(DayRelativeToNearestHCT, -10, 0)) %>%
  group_by(PatientID, NearestHCTTimepoint, TransplantEpisodeID) %>%
  summarise(first_quin_day = min(DayRelativeToNearestHCT, na.rm = TRUE), .groups = "drop")

# Episode-specific infection events relative to nearest transplant.
# This keeps one row per reported infectious event, mapped to nearest HCT.
tblinfections <- suppressMessages(read_csv("data/Liao_etal_2021/allInfectionsSD.csv")) %>%
  filter(PatientID %in% all_patients) %>%
  mutate(
    NearestHCTTimepoint = mapply(
      get_nearest_hct_timepoint,
      PatientID,
      Day,
      MoreArgs = list(hct_meta = tblhctmeta)
    ),
    DayRelativeToNearestHCT = Day - NearestHCTTimepoint,
    TransplantEpisodeID = paste(PatientID, NearestHCTTimepoint, sep = "__"),
    is_proteo_bsi = InfectiousAgent %in% proteobacteria_agents
  ) %>%
  select(PatientID, NearestHCTTimepoint, TransplantEpisodeID, DayRelativeToNearestHCT, is_proteo_bsi)

# First Proteobacteria BSI day during neutropenia for each transplant episode.
# This is the event label used downstream for case/control model features.
first_infection <- tblinfections %>%
  filter(is_proteo_bsi) %>%
  inner_join(
    tblwbc_status %>% filter(Status == "Neutropenia"),
    by = c("PatientID", "NearestHCTTimepoint", "TransplantEpisodeID", "DayRelativeToNearestHCT")
  ) %>%
  group_by(PatientID, NearestHCTTimepoint, TransplantEpisodeID) %>%
  summarise(first_infection_day = min(DayRelativeToNearestHCT, na.rm = TRUE), .groups = "drop")

# First engraftment day per transplant episode.
# For non-infected episodes, this acts as the feature cutoff boundary.
engraftment_day <- tblwbc_status %>%
  filter(Status == "Engraftment") %>%
  group_by(PatientID, NearestHCTTimepoint, TransplantEpisodeID) %>%
  summarise(engraftment_day = min(DayRelativeToNearestHCT, na.rm = TRUE), .groups = "drop")

# -----------------------------------------------------------------------------
# 6) Build sample metadata table restricted to analysis day window
# -----------------------------------------------------------------------------

message("Preparing stool sample metadata in day window [-10, 30]...")

# Sample metadata table mapped to nearest transplant episode and filtered to the
# analysis window used by Fig6C/Fig6D.
sample_meta <- suppressMessages(
  read_csv(
    "data/Liao_etal_2021/tblASVsamples.csv",
    col_types = cols(.default = col_guess(), Pool = col_character())
  )
) %>%
  filter(PatientID %in% all_patients) %>%
  transmute(
    SampleID,
    PatientID,
    Timepoint,
    NearestHCTTimepoint = mapply(
      get_nearest_hct_timepoint,
      PatientID,
      Timepoint,
      MoreArgs = list(hct_meta = tblhctmeta)
    ),
    DayRelativeToNearestHCT = Timepoint - NearestHCTTimepoint,
    TransplantEpisodeID = paste(PatientID, NearestHCTTimepoint, sep = "__")
  ) %>%
  distinct(SampleID, .keep_all = TRUE) %>%
  filter(between(DayRelativeToNearestHCT, -10, 30))

# -----------------------------------------------------------------------------
# 7) Extract taxa abundances required by Fig6C/Fig6D
# -----------------------------------------------------------------------------

message("Extracting required family/phylum abundances...")

family_targets <- c(
  "Bacteroidaceae",
  "Barnesiellaceae",
  "Dysgonomonadaceae",
  "Marinifilaceae",
  "Rikenellaceae",
  "Tannerellaceae",
  "Prevotellaceae",
  "Enterobacteriaceae",
  "Pseudomonadaceae"
)
phylum_targets <- c("Proteobacteria")

# Family-level relative abundance table (selected taxa only).
family_abund <- extract_selected_abundances(
  file_path = "data/Liao_etal_2021/tblcounts_family_wide.csv",
  taxon_col = "Family",
  target_taxa = family_targets
)

# Phylum-level relative abundance table (Proteobacteria only).
phylum_abund <- extract_selected_abundances(
  file_path = "data/Liao_etal_2021/tblcounts_phylum_wide.csv",
  taxon_col = "Phylum",
  target_taxa = phylum_targets
)

# -----------------------------------------------------------------------------
# 8) Assemble final analysis input table
# -----------------------------------------------------------------------------

message("Assembling final bsi_model_input table...")

# Episode-level cutoff table to attach shared clinical labels to all samples in
# the same transplant episode.
episode_cutoffs <- sample_meta %>%
  distinct(PatientID, NearestHCTTimepoint, TransplantEpisodeID) %>%
  left_join(first_quin_day, by = c("PatientID", "NearestHCTTimepoint", "TransplantEpisodeID")) %>%
  left_join(first_infection, by = c("PatientID", "NearestHCTTimepoint", "TransplantEpisodeID")) %>%
  left_join(engraftment_day, by = c("PatientID", "NearestHCTTimepoint", "TransplantEpisodeID")) %>%
  mutate(has_infection = !is.na(first_infection_day))

# Final model input table used as the sole input to scripts 05 and 06.
# Contains per-sample taxa abundances plus per-episode clinical cutoffs.
bsi_model_input <- sample_meta %>%
  left_join(family_abund, by = "SampleID") %>%
  left_join(phylum_abund, by = "SampleID") %>%
  left_join(episode_cutoffs, by = c("PatientID", "NearestHCTTimepoint", "TransplantEpisodeID")) %>%
  mutate(across(ends_with("_abund"), ~ replace_na(.x, 0))) %>%
  select(
    SampleID,
    PatientID,
    TransplantEpisodeID,
    NearestHCTTimepoint,
    DayRelativeToNearestHCT,
    first_quin_day,
    first_infection_day,
    engraftment_day,
    has_infection,
    Proteobacteria_abund,
    Enterobacteriaceae_abund,
    Pseudomonadaceae_abund,
    Bacteroidaceae_abund,
    Barnesiellaceae_abund,
    Dysgonomonadaceae_abund,
    Marinifilaceae_abund,
    Rikenellaceae_abund,
    Tannerellaceae_abund,
    Prevotellaceae_abund
  )

# -----------------------------------------------------------------------------
# 9) Write output
# -----------------------------------------------------------------------------

write_csv(bsi_model_input, "data/figure6/bsi_model_input.csv")
message("Saved: data/figure6/bsi_model_input.csv")
