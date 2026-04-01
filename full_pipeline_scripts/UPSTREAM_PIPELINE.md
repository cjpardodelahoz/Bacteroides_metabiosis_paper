# Upstream Assembly + Binning + MAG/CGC/PUL Pipeline

This folder contains the scripts needed to generate metagenome assemblies and VAMB bins from raw reads, then run the downstream MAG/CGC/PUL workflow used for Figure 6.

Return to the main project page: [README](../README.md).

## Folder contents

- `slurm/`: SLURM job scripts for assembly, binning, and annotation (called by bash_blocks wrappers).
- `bash_blocks/`: Numbered helper scripts for pipeline execution:
  - `01_run_metaspades_assembly.sh`: Submit per-sample assembly jobs
  - `02_build_successful_assemblies_list.sh`: Extract list of successful assemblies from metaSPAdes output
  - `03_build_patient_sample_lists.sh`: Group samples by patient for VAMB
  - `04_run_vamb_binning.sh`: Submit multi-sample VAMB binning jobs
  - `05_compile_vamb_bins.sh`: Consolidate VAMB bins for downstream processing
  - `06_download_gtdb_r226_refs.sh`: Download GTDB phylogenetic references
  - `07_download_susd_hmms.sh`: Download SusD PFAM profiles (optional)
  - `08_submit_dbcan_signalp_jobs.sh`: Submit annotation jobs (dbCAN, SignalP)
  - `09_compile_cgcs.sh`: Compile carbohydrate gene cluster results
  - `10_compile_signalp.sh`: Compile signal peptide predictions
  - `11_compile_puls.sh`: Compile polysaccharide utilization locus predictions
- `concatenate_assemblies_for_vamb.sh`: Helper for per-patient assembly concatenation before VAMB.
- `merge_aemb.py`: Helper to merge `strobealign --aemb` outputs into VAMB abundance matrix.
- `get_pulfeatures.py`, `extract_gene_aa.py`: Helper scripts copied from `software/custom/`.

## Typical execution order

### A) Metagenome Assembly

1. Put metagenomic FASTQ files in `data/reads/`.
2. Create `data/read_metadata.csv` with columns: `SRA_accession,SampleID,PatientID`
3. Submit the per-sample assembly job (fastp QC + metaSPAdes):

```bash
bash full_pipeline_scripts/bash_blocks/01_run_metaspades_assembly.sh
```

### B) Multi-sample Binning

After assembly completes:

1. Build list of successful assemblies (scans metaSPAdes output and records all samples that produced contigs):

```bash
bash full_pipeline_scripts/bash_blocks/02_build_successful_assemblies_list.sh
```

Output: `analyses/bacteroides_pul/metagenomes/metaspades_successful_samples.txt`

2. Build patient sample lists for VAMB (groups successful samples by PatientID):

```bash
bash full_pipeline_scripts/bash_blocks/03_build_patient_sample_lists.sh
```

Output: `analyses/bacteroides_pul/binning/short/isabl1/patient_samples/{PatientID}.txt` (one file per patient)

3. Submit the multi-sample VAMB job:

```bash
bash full_pipeline_scripts/bash_blocks/04_run_vamb_binning.sh
```

4. Compile all patient bins into one folder (consolidates VAMB output for downstream processing):

```bash
bash full_pipeline_scripts/bash_blocks/05_compile_vamb_bins.sh
```

Output: `analyses/bacteroides_pul/binning/short/isabl1/vamb/multi_bins/` (contains all bins with PatientID prefix)

### C) CGC Prediction and Substrate Inference

After VAMB binning completes:

1. Download GTDB release 226 reference files (phylogenetic tree and taxonomy for MAG classification):

```bash
bash full_pipeline_scripts/bash_blocks/06_download_gtdb_r226_refs.sh
```

Outputs:
- `data/gtdb/bac120_r226.tree` (phylogenetic tree)
- `data/gtdb/bac120_taxonomy_r226.tsv` (taxonomy assignments)
- `data/gtdb/bac120_metadata_r226.tsv.gz` (extended metadata)

2. (Optional) Download SusD PFAM HMMs (for refined substrate prediction of starch-utilization PULs):

```bash
bash full_pipeline_scripts/bash_blocks/07_download_susd_hmms.sh
```

Output: `hmms/susD/` (contains PF07980, PF12741, PF12771, PF14322 HMM profiles)

3. Run dbCAN (CAZyme annotation) and SignalP (secretion signal prediction) jobs on cluster:

```bash
bash full_pipeline_scripts/bash_blocks/08_submit_dbcan_signalp_jobs.sh
```

This submits four array jobs for parallel processing of MAGs.

4. Compile CGC (Carbohydrate Gene Cluster) results from dbCAN output:

```bash
bash full_pipeline_scripts/bash_blocks/09_compile_cgcs.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_cgcs.tsv` (one row per CGC per MAG)

5. Compile SignalP (secreted protein) results:

```bash
bash full_pipeline_scripts/bash_blocks/10_compile_signalp.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_signalp.tsv` (signal peptide predictions for all ORFs)

6. Compile PUL substrate predictions (includes dbCAN, SignalP, and HMM-based annotations):

```bash
bash full_pipeline_scripts/bash_blocks/11_compile_puls.sh
```

Output: `analyses/bacteroides_pul/mag_pul_summary/compiled_puls.tsv` (substrate-level predictions per CGC)

## Notes

- SLURM logs are written to `log/slurm/`.
- Assembly and VAMB scripts keep `SampleID` labels in downstream output paths.
- These scripts are provided for reproducibility/provenance; they require the corresponding MAG outputs and compute environment.
- Figure-only reproduction from precomputed inputs does **not** require this upstream pipeline.
- If you only need Figure 6 outputs, use the main reproduction instructions in [README](../README.md#figure-6-reproduction).
