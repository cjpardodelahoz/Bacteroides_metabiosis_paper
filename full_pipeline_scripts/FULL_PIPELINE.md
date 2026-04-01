# Full Assembly + Binning + MAG/CGC/PUL Pipeline

This folder contains scripts to run the complete workflow from raw reads to MAG-level CGC/PUL summaries used by the Figure 6 data-prep scripts.

Return to the main project page: [README](../README.md).

## Folder contents

- `slurm/`: SLURM job scripts for assembly, binning, CheckM2/GTDB, dbCAN, and SignalP.
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
- `build_nc_mags.R`: R script that combines CheckM2 + GTDB outputs and generates the filtered MAG list.
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

### E) Regenerate Figure 6 input tables from upstream outputs

After sections C and D are complete, regenerate Figure 6 pre-plot data tables:

1. Build `cgc_data.csv` from compiled CGC/SignalP/PUL + CheckM2/GTDB outputs:

```bash
conda run -n figure6_r Rscript figure6_scripts/00_generate_cgc_data.R
```

2. Build `bsi_model_input.csv` from clinical/abundance source tables [(Liao et al. 2021)](https://doi.org/10.1038/s41597-021-00860-8). The tables in .csv format are available in a [FigShare repository](https://doi.org/10.6084/m9.figshare.13584986), and should be placed under `data/Liao_etal_2021`. After that, you can run:

```bash
conda run -n figure6_r Rscript figure6_scripts/00_generate_bsi_model_input.R
```

Outputs:
- `data/figure6/cgc_data.csv`
- `data/figure6/bsi_model_input.csv`

## Notes

- If you only need final Figure 6 panels from precomputed inputs, use the quickstart in [README](../README.md#figure-6-quickstart).
