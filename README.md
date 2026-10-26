# *Bacteroides* metabiosis paper

This repository contains the code to reproduce the panels of Figure 6 and Figure S6 in [our paper (Wucher et al.)]() linking *Bacteroides* metabiosis to increased risk of Pseudomonadota bloodstream infection. This mainly concerns the inference of CAZyme gene clusters (CGCs) for peri/extracellular polysaccharide degradation in metagenome-assembled genomes, and PICRUSt2-based prediction of digestive CAZyme content from 16S profiles of allo-HCT patients at MSKCC.

## Quickstart

### Download code and data

You can quickly reproduce Figure 6 and Figure S6 by cloning this repository and downloading the pre-processed data from the paper's [Data repository](). From the data download, copy the folders `figure6` and `figureS6` under `data/` in this repo.

The Figure 6C, 6D and S6B scripts also read 16S data from [Liao et al. 2021](https://doi.org/10.1038/s41597-021-00860-8). Download these tables from the [FigShare repository](https://doi.org/10.6084/m9.figshare.13584986) and place them under `data/Liao_etal_2021/`:

- `tblcounts_asv_wide.csv`
- `tblASVsamples.csv`
- `tblhctmeta.csv`
- `tbldrug.csv`

All analyses use the ASV taxonomy (Phylum, Family, Genus) from Chen Liao's [oral bacteria repository](https://github.com/liaochen1988/Oral_bacterial_manuscript_revision/blob/main/Fig4%7CFigS1_S2%7CEDFig6_9%7CTableS5/taxonomy.csv). Download `taxonomy.csv` into `data/` before running the scripts:

```bash
curl -L -o data/taxonomy.csv \
  "https://raw.githubusercontent.com/liaochen1988/Oral_bacterial_manuscript_revision/main/Fig4%7CFigS1_S2%7CEDFig6_9%7CTableS5/taxonomy.csv"
```

### Set R environment

You will need R v4.4.3 and packages `tidyverse`, `data.table`, `R.utils`, `ape`, `aplot`, `patchwork`, `ggrepel`, `survival`, and `ggtree`. You can install them independently or use the yml file to recreate my conda environment with all required dependencies:

```bash
conda env create -f figure6_environment.yml
```

### Reproduce Figure 6 and Figure S6 panels

Run from repository root:

```bash
# Download GTDB tree/taxonomy references required by Figure 6A/6B
bash full_pipeline_scripts/bash_blocks/09_download_gtdb_r226_refs.sh
```

This downloads GTDB files into `data/gtdb/`. Then, run the R scripts to get the plots:

```bash
conda run -n figure6_r Rscript figure6_scripts/01_plot_figure6a.R
conda run -n figure6_r Rscript figure6_scripts/02_plot_figure6b.R
conda run -n figure6_r Rscript figure6_scripts/03_plot_figure6c.R
conda run -n figure6_r Rscript figure6_scripts/04_plot_figure6d.R
conda run -n figure6_r Rscript figureS6_scripts/01_plot_figureS6a.R
conda run -n figure6_r Rscript figureS6_scripts/02_plot_figureS6b.R
```

You should get the following outputs:

| Panel | Plot | Associated table |
|---|---|---|
| 6A | `results/figure6/Fig6A.pdf` | |
| 6B | `results/figure6/Fig6B.pdf` | `results/figure6/Fig6B_family_stats.csv` |
| 6C | `results/figure6/Fig6C.pdf` | `results/figure6/Fig6C_patient_medians.csv` |
| 6D | `results/figure6/Fig6D.pdf` | `results/figure6/Fig6D_model_results.csv` |
| S6A | `results/figureS6/FigS6A.pdf` | `results/figureS6/FigS6A_substrate_enrichment.csv` |
| S6B | `results/figureS6/FigS6B.pdf` | `results/figureS6/FigS6B_spearman.csv` |

`figure6_scripts/03_plot_figure6c.R` builds `data/figure6/family_abundance.csv` from the Liao et al. 2021 tables if it is not already present.

## Full pipeline

If you want to see the full pipeline to get MAGs-to-CGC/PUL from raw reads, and how the pre-processed data tables are generated, see:

- [Full pipeline guide](full_pipeline_scripts/FULL_PIPELINE.md)
