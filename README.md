# *Bacteroides* metabiosis paper

This repository contains the code to reproduce the panels of Figure 6 in [our paper (Wucher et al.)]() linking *Bacteroides* metabiosis to increased risk of Pseudomonadota bloodstream infection. This mainly concerns the inference of CAZyme gene clusters for peri/extracellular polysaccharide degradation and predictive modeling of Pseudomonadota BSI in allo-HCT patients at MSKCC.

## Figure 6 quickstart

### Dowload code and data

You can quickly reproduce Figure 6 by cloning this repository and downloading the pre-processed CGC and patient data from the paper's [Data repository](). From the data download, copy the folder `figure6` under `data/figure6/` in this repo. You will need files `cgc_data.csv` and `bsi_model_input.csv`.

### Set R environment

You will also need R v4.4.3 and packages `tidyverse`, `data.table`, `ape`, `aplot`, `pROC`, and `ggtree`. You can install them independently or use the yml file to recreate my conda environment with all required dependencies:

```bash
conda env create -f figure6_environment.yml
```

### Reproduce Figure 6 panels

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
```

You should get the following outputs:

- `data/figure6/linearmodels_auc_cv_results.csv`
- `results/figure6/Fig6A.pdf`
- `results/figure6/Fig6B.pdf`
- `results/figure6/Fig6C.pdf`
- `results/figure6/Fig6D.pdf`

## Full pipeline

If you want to see the full pipeline to get MAGs-to-CGC/PUL from raw reads, see:

- [Full pipeline guide](full_pipeline_scripts/FULL_PIPELINE.md)
