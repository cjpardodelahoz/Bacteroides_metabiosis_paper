# Full Assembly + Binning + MAG/CGC/PUL + PICRUSt2 Pipeline

This folder contains scripts to run the complete workflow from raw reads to the MAG-level CGC/PUL summaries, metagenome-level CAZyme features, and PICRUSt2 custom CAZyme predictions used by the Figure 6 and Figure S6 data-prep scripts.

Return to the main project page: [README](../README.md).

## Folder contents

- `slurm/`: SLURM job scripts for assembly, binning, CheckM2/GTDB, dbCAN, SignalP, read mapping, and PICRUSt2.
- `bash_blocks/`: numbered execution wrappers (run in order):
  - `01_run_metaspades_assembly.sh`
  - `02_build_successful_assemblies_list.sh`
  - `03_build_patient_sample_lists.sh`
  - `04_run_vamb_binning.sh`
  - `05_compile_vamb_bins.sh`
  - `06_run_checkm2.sh`
  - `07_run_gtdb.sh`
  - `08_build_nc_mags.sh`
  - `09_download_gtdb_r226_refs.sh`
  - `10_submit_dbcan_signalp_jobs.sh`
  - `11_compile_cgcs.sh`
  - `12_compile_signalp.sh`
  - `13_compile_puls.sh`
  - `14_compile_dbcansub_substrates.sh`
  - `15_submit_metagenome_dbcan_jobs.sh`
  - `16_build_metagenome_dbcan_successful_list.sh`
  - `17_submit_metagenome_signalp_abund_jobs.sh`
  - `18_submit_metagenome_sample_features.sh`
  - `19_merge_metagenome_sample_features.sh`
  - `20_list_picrust_reference_genomes.sh`
  - `21_download_picrust_reference_genomes.sh`
  - `22_submit_bacref_dbcan_signalp_jobs.sh`
  - `23_build_custom_trait_tables.sh`
  - `24_build_asv_sequences.sh`
  - `25_run_picrust_placement.sh`
  - `26_run_custom_trait_hsp.sh`
- `build_nc_mags.R`: R script that combines CheckM2 + GTDB outputs and generates the filtered MAG list.
- `build_custom_trait_table.py`: Python script that builds the PICRUSt2 custom CAZyme trait tables from reference-genome dbCAN + SignalP outputs.
- `concatenate_assemblies_for_vamb.sh`, `merge_aemb.py`: helpers for VAMB input preparation.

## Bioinformatic pipeline

### A) Metagenome Assembly

1. Place metagenomic FASTQ files under `data/reads/`.
2. Create `data/read_metadata.csv` with columns:
   - `SRA_accession,SampleID,PatientID`
3. Submit per-sample assembly (fastp + metaSPAdes):

```bash
bash full_pipeline_scripts/bash_blocks/01_run_metaspades_assembly.sh
```

### B) Multi-sample Binning

After assembly completes:

1. Build list of successful assemblies:

```bash
bash full_pipeline_scripts/bash_blocks/02_build_successful_assemblies_list.sh
```

Output: `analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt`

2. Build patient sample lists for VAMB:

```bash
bash full_pipeline_scripts/bash_blocks/03_build_patient_sample_lists.sh
```

Output: `analyses/bacteroides_pul/binning/short/isabl1/patient_samples/{PatientID}.txt`

3. Submit multi-sample VAMB jobs:

```bash
bash full_pipeline_scripts/bash_blocks/04_run_vamb_binning.sh
```

4. Compile bins into one directory:

```bash
bash full_pipeline_scripts/bash_blocks/05_compile_vamb_bins.sh
```

Output: `analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins/`

### C) MAG QC and taxonomy

After bin compilation completes:

1. Run CheckM2 on compiled bins:

```bash
bash full_pipeline_scripts/bash_blocks/06_run_checkm2.sh
```

Output: `analyses/bacteroides_pul/checkm2/quality_report.tsv`

2. Run GTDB-Tk on compiled bins:

```bash
bash full_pipeline_scripts/bash_blocks/07_run_gtdb.sh
```

Output: `analyses/bacteroides_pul/gtdb/gtdbtk.bac120.summary.tsv`

3. Build QC/taxonomy summary and filtered NC MAG list (R-based step):

```bash
bash full_pipeline_scripts/bash_blocks/08_build_nc_mags.sh
```

Outputs:
- `analyses/bacteroides_pul/mag_pul_summary/mag_qc_taxonomy_summary.tsv`
- `analyses/bacteroides_pul/isabl1_nc_mags.txt`

### D) CGC/PUL inference

After section C is complete:

4. Download GTDB release 226 tree/taxonomy references for Figure 6A/6B plotting:

```bash
bash full_pipeline_scripts/bash_blocks/09_download_gtdb_r226_refs.sh
```

Outputs:
- `data/gtdb/bac120_r226.tree`
- `data/gtdb/bac120_taxonomy_r226.tsv`
- `data/gtdb/bac120_metadata_r226.tsv.gz`

5. Submit dbCAN and SignalP jobs (array jobs over filtered MAG list):

```bash
bash full_pipeline_scripts/bash_blocks/10_submit_dbcan_signalp_jobs.sh
```

6. Compile CGC results:

```bash
bash full_pipeline_scripts/bash_blocks/11_compile_cgcs.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_cgcs.tsv`

7. Compile SignalP results:

```bash
bash full_pipeline_scripts/bash_blocks/12_compile_signalp.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_signalp.tsv`

8. Compile PUL substrate predictions:

```bash
bash full_pipeline_scripts/bash_blocks/13_compile_puls.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_puls.tsv`

9. Compile dbCAN-sub substrate annotations per protein (used by Figure 6B):

```bash
bash full_pipeline_scripts/bash_blocks/14_compile_dbcansub_substrates.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_dbcansub_substrates.tsv.gz`

### E) Metagenome-level CGC annotation and CAZyme features

After sections A and B are complete (dbCAN runs on the `contigs_1000.fasta` files written during binning), annotate each metagenome assembly and summarize its digestive CAZyme content. These features are compared with PICRUSt2 predictions in Figure S6B.

1. Submit dbCAN on each metagenome assembly:

```bash
bash full_pipeline_scripts/bash_blocks/15_submit_metagenome_dbcan_jobs.sh
```

Output: `analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/{SampleID}/`

2. List metagenomes where dbCAN produced CGC proteins:

```bash
bash full_pipeline_scripts/bash_blocks/16_build_metagenome_dbcan_successful_list.sh
```

Output: `analyses/bacteroides_pul/metagenome_pul_prediction/isabl1_dbcan_successful_samples.txt`

3. Submit SignalP on CGC proteins, and read mapping + per-gene coverage + dbCAN-sub substrate gene lists (dbcan_utils). Reads are located through `data/read_metadata.csv` as in section A:

```bash
bash full_pipeline_scripts/bash_blocks/17_submit_metagenome_signalp_abund_jobs.sh
```

Outputs:
- `analyses/bacteroides_pul/metagenome_pul_prediction/isabl1/{SampleID}/signalp/prediction_results.txt`
- `analyses/bacteroides_pul/metagenome_pul_abund/{SampleID}/{SampleID}.depth.txt`
- `analyses/bacteroides_pul/metagenome_pul_abund/{SampleID}/fam_substrate_abund.out`

4. After step 3 completes, compute per-sample features (digestive CAZyme genes, their SignalP-positive subset, and the secreted host glycan / pectin subsets as gene counts, TPM, and aligned reads):

```bash
bash full_pipeline_scripts/bash_blocks/18_submit_metagenome_sample_features.sh
```

Output: `analyses/bacteroides_pul/metagenome_features/per_sample/{SampleID}.tsv`

5. Merge per-sample features:

```bash
bash full_pipeline_scripts/bash_blocks/19_merge_metagenome_sample_features.sh
```

Output: `analyses/bacteroides_pul/metagenome_features/metagenome_sample_features.tsv`

### F) PICRUSt2 custom CAZyme trait predictions

This section is independent of sections A-E. It annotates the PICRUSt2 bacterial reference genomes with the same dbCAN + SignalP workflow used for the MAGs, builds a custom trait table of digestive CAZyme `<family>_<EC>` gene copies, and predicts those traits for the Liao et al. 2021 ASVs. It requires PICRUSt2 2.6.3 in a conda environment named `picrust2`, the Liao et al. 2021 tables under `data/Liao_etal_2021`, and the dbCAN database used in section D.

1. List the PICRUSt2 bacterial reference genome accessions:

```bash
bash full_pipeline_scripts/bash_blocks/20_list_picrust_reference_genomes.sh
```

Output: `analyses/picrust_custom_traits/bacteria_genomes.txt`

2. Download GTDB r214.1 representative genomes (~75 GB) and keep the reference genomes:

```bash
bash full_pipeline_scripts/bash_blocks/21_download_picrust_reference_genomes.sh
```

Output: `analyses/picrust_custom_traits/bacteria_genomes/{accession}_genomic.fna.gz`

3. Submit dbCAN and SignalP on the reference genomes (three batches; SignalP batches wait for the matching dbCAN batch):

```bash
bash full_pipeline_scripts/bash_blocks/22_submit_bacref_dbcan_signalp_jobs.sh
```

Output: `analyses/picrust_custom_traits/bacref_pul_prediction/{accession}/`

4. Build the custom trait tables (secreted digestive CAZymes, and all digestive CAZymes with the same columns) and copy the dbCAN family + EC substrate mapping:

```bash
bash full_pipeline_scripts/bash_blocks/23_build_custom_trait_tables.sh
```

Outputs:
- `analyses/picrust_custom_traits/custom_trait_table_secreted.tsv`
- `analyses/picrust_custom_traits/custom_trait_table_all_digestive.tsv`
- `analyses/picrust_custom_traits/dbcan_fam-substrate-mapping.tsv`

5. Write the ASV sequences from `tblASVtaxonomy_silva132_v4v5_filter.csv` (Liao et al. 2021) as FASTA. Only the `Sequence` column is used here; ASV taxonomy for all analyses comes from `data/taxonomy.csv` (see [README](../README.md#download-code-and-data)):

```bash
bash full_pipeline_scripts/bash_blocks/24_build_asv_sequences.sh
```

Output: `analyses/picrust_custom_traits/placement/asv_sequences.fasta`

6. Place ASVs into the PICRUSt2 bacterial reference tree and predict 16S copy number and NSTI:

```bash
bash full_pipeline_scripts/bash_blocks/25_run_picrust_placement.sh
```

Outputs:
- `analyses/picrust_custom_traits/placement/out.tre`
- `analyses/picrust_custom_traits/placement/marker_predicted_and_nsti.tsv.gz`

7. After steps 4 and 6 complete, predict the custom traits for each ASV:

```bash
bash full_pipeline_scripts/bash_blocks/26_run_custom_trait_hsp.sh
```

Outputs:
- `analyses/picrust_custom_traits/hsp/cazy_custom_predicted_secreted.tsv.gz`
- `analyses/picrust_custom_traits/hsp/cazy_custom_predicted_all_digestive.tsv.gz`

### G) Regenerate Figure 6 and Figure S6 input tables from upstream outputs

After sections C-F are complete, regenerate the pre-plot data tables. The 16S and clinical source tables from [Liao et al. 2021](https://doi.org/10.1038/s41597-021-00860-8) are available in a [FigShare repository](https://doi.org/10.6084/m9.figshare.13584986), and should be placed under `data/Liao_etal_2021`.

1. Build `cgc_data.csv` and `cgc_dbcansub_substrates.csv.gz` from compiled CGC/SignalP/PUL/dbCAN-sub + CheckM2/GTDB outputs:

```bash
conda run -n figure6_r Rscript figure6_scripts/00_generate_cgc_data.R
```

2. Stage the PICRUSt2 predictions (section F), the dbCAN substrate mapping, and the metagenome features (section E). The frozen Figure 1E matched design (`data/figure6/fig1e_matched_sets.csv`, `data/figure6/fig1e_history_samples.csv`) and the ASV taxonomy (`data/taxonomy.csv`) are distributed inputs and are not regenerated by this pipeline:

```bash
conda run -n figure6_r Rscript figure6_scripts/00_generate_picrust_data.R
```

3. Build the Figure 6C family abundance table from the Liao et al. 2021 tables and `data/taxonomy.csv`:

```bash
conda run -n figure6_r Rscript figure6_scripts/00_generate_family_abundance.R
```

Outputs:
- `data/figure6/cgc_data.csv`
- `data/figure6/cgc_dbcansub_substrates.csv.gz`
- `data/figure6/picrust_*.tsv.gz`, `data/figure6/dbcan_*`
- `data/figure6/family_abundance.csv`
- `data/figureS6/metagenome_sample_features.tsv`

## Notes

- If you only need final Figure 6 and Figure S6 panels from precomputed inputs, use the quickstart in [README](../README.md#quickstart).
- Array upper bounds in `slurm/` scripts match our sample and MAG lists; update them to the number of rows of the corresponding list if your inputs differ.
- The dbCAN database path (`/data1/xavierj/carlos/dbs/dbcan`) is set in the dbCAN SLURM scripts and in `23_build_custom_trait_tables.sh`; change it to your local database.
