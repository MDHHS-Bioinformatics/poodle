# ![MI-Bioinformatics/PoODLE](docs/images/poodle_logo_light.png#gh-light-mode-only) ![nf-core/poodle](docs/images/poodle_logo_light.png#gh-dark-mode-only)

# PoODLE

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)


**PoODLE** (Phylogenomic Overview for the Detection of Linkages for Epidemiologists)  is a **Nextflow** pipeline designed for genomic analysis of bacterial clusters. This pipeline runs Snippy, Gubbins (optional), Panaroo, and MashTree (optional); identifies SNP-based linkages and generates a report with interactive plots to facilitate interpretations.

Designed for surveillance purposes as it first identifies if Snippy-run results already exist for samples from the same cluster. If they exist it checks if the same reference was used, if a different reference is used it repeats the results for all the samples in the cluster. Snippy-run is the step that uses most of the computing resources and takes long time. In surveillace, clusters keep growing so not having to repeat the analysis for all the samples everytime that a single new sample is included it saves resources and time.


![Pipeline Workflow](./docs/images/poodle_flowchart.png)

# Table of Contents
- [Pipeline summary](#-pipeline-summary)
- [Quick Start](#-quick-start)
- [Parameters](#parameters)
- [Output overview](#-output-overview)
- [Key output files](#-key-output-files)
- [Best practices & caveats](#-best-practices--caveats)
- [Citations](#-citations)
- [Credits & Community](#credits--community)
- [License](#-license)


---

## 🧩 Pipeline summary

1. Identify reference-based SNPs with [`Snippy`](https://github.com/tseemann/snippy)-run for each sample.
2. Make a core genome alignment with [`Snippy`](https://github.com/tseemann/snippy)-core, generate a SNP tree with [`IQ-TREE`](https://www.iqtree.org/) and calculate SNP distances with [`snp-dists`](https://github.com/tseemann/snp-dists).
3. Mask recombinant sites with [`Gubbins`](https://github.com/nickjcroucher/gubbins) (optional), extract ACGT positions with [`snp-sites`](https://sanger-pathogens.github.io/snp-sites/), generate a SNP tree with [`IQ-TREE`](https://www.iqtree.org/) and calculate SNP distances with [`snp-dists`](https://github.com/tseemann/snp-dists).
4. Pangenome profile (gene presence-absence) with [`Panaroo`](https://github.com/gtonkinhill/panaroo) and calculate gene presence-absence distances.
5. Make a tree with Mash distances using [`MashTree`](https://github.com/lskatz/mashtree) (optional).
6. Summary report in HTML format including trees, pangenome profile and distance matrices.

![Pipeline Workflow](./docs/images/poodle_flowchart.png)

---

## ⚡ Quick Start

### 1. Install prerequisites

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)
2. Install [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility.

> [!NOTE]  
> If using **Singularity** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later. For example: 
> ```
> export NXF_SINGULARITY_CACHEDIR="/path/to/singularity_cache"
> ``````

---

### 2. Prepare your manifest file

Create a CSV file containing absolute paths to the following: QC-trimmed FASTQ files, GFFs, assemblies, and reference. Snippy supports inputs in three formats: paired-end reads, single-end reads, or assemblies

- **Paired-end reads**: Include paths for both `fastq_1` and `fastq_2`.
- **Single-end reads**: Leave the `fastq_2` column blank.
- **Assemblies only**: Leave both `fastq_1` and `fastq_2` columns blank.

The following columns are **mandatory**:
- `sample`: unique ID (no spaces recommended)
- `gff`: absolute path to GFF annotations for the sample (uncompressed GFF only; .gz or .zip not supported)
- `assembly`: absolute path to FASTA assembly for the sample (uncompressed FASTA only; .gz or .zip not supported)
- `cluster_id`: genomic context group identification (no spaces recommended)
- `species`: species (no spaces recommended) 
- `reference`: absolute path to FASTA assembly for the reference (uncompressed FASTA only; .gz or .zip not supported)

Make sure to provide values for these columns even if certain input types do not require `fastq` paths.

```console
sample,fastq_1,fastq_2,gff,assembly,cluster_id,species,reference
SAMPLE_1,/path/to/SAMPLE1_1.trim.fastq.gz,/path/to/SAMPLE1_2.trim.fastq.gz,/path/to/SAMPLE1.gff,/path/to/SAMPLE1.fasta,HC1-C1,Escherichia_coli,/path/to/reference1.fasta
SAMPLE_2,/path/to/SAMPLE2_1.trim.fastq.gz,/path/to/SAMPLE2_2.trim.fastq.gz,/path/to/SAMPLE2.gff,/path/to/SAMPLE2.fasta,HC1-C1,Escherichia_coli,/path/to/reference1.fasta
SAMPLE_3,/path/to/SAMPLE3_1.trim.fastq.gz,/path/to/SAMPLE3_2.trim.fastq.gz,/path/to/SAMPLE3.gff,/path/to/SAMPLE3.fasta,outbreak_facilityA,Pseudomonas aeruginosa,/path/to/reference2.fasta
SAMPLE_4,/path/to/SAMPLE4.trim.fastq.gz,,/path/to/SAMPLE4.gff,/path/to/SAMPLE4.fasta,outbreak_facilityA,Pseudomonas aeruginosa,/path/to/reference2.fasta
SAMPLE_5,,,/path/to/SAMPLE5.gff,/path/to/SAMPLE5.fasta,outbreak_facilityA,Pseudomonas aeruginosa,/path/to/reference2.fasta
SAMPLE_6,,,/path/to/SAMPLE6.gff,/path/to/SAMPLE6.fasta,outbreak_facilityA,Pseudomonas aeruginosa,/path/to/reference2.fasta
SAMPLE_7,,,/path/to/SAMPLE7.gff,/path/to/SAMPLE7.fasta,HC1-C1,Escherichia_coli,/path/to/reference1.fasta
```

More details in [Usage](docs/usage.md)

> [!NOTE]
> While Snippy supports assemblies as input for SNP analysis, these results can be inflated/inaccurate. Always prefer using quality-trimmed reads when possible.

### 4. Run your analyses

### Basic run

```bash
nextflow run MI-Bioinformatics/poodle \
  --input manifest.csv \
  --outdir corge \
  --gubbins \
  --mashtree \
  -profile singularity
```
>[!NOTE]
>This command clones (download) the repo to ~/.nextflow/assets/MI-Bioinformatics/poodle. You can download the pipeline in a different location using `git clone https://github.com/MI-Bioinformatics/poodle.git`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/poodle ...`). More details in [Usage](docs/usage.md)

> [!TIP]
> After the run has been successfully finished, you can safely remove the `work` directory located at `<outdir>/work`.

## Parameters

### **📥 Input & Core Parameters**

| Parameter          | Required | Default        | Description                                                                                                |
| ------------------ | :------: | -------------- | ---------------------------------------------------------------------------------------------------------- |
| `--input`          |     ✓    | –              | Manifest CSV (`sample,fastq_1,fastq_2,gff,assembly,cluster_id,species,reference`).                                                                  |
| `--outdir`         |     ✓    | `$PWD/poodle`   | Output directory root.|
| `--gubbins` |     –    | `false`              | Filter out recombinant sites with Gubbins |
| `--mashtree` |     –    | `false`              | Analyze genomic distances and generate a Mashtree |
| `--logo_report`           |     ✓    | `assets/DNA_logo.png`      | Logo in PNG format to include in the report header     |
| `--previous_results`     |     –    | –              | Path to previous results. By default, the pipeline looks for prior Snippy results for the same cluster in the outdir.                |
| `--save_snippy_run`     |     –    | `true`              | Do not publish Snippy run results. By default, the pipeline saves the Snippy-run results per sample  |
| `--email`     |     –    | –              | Email address for completion summary  |
| `--multiqc_title`     |     –    | `true`              | MultiQC report title. Printed as a page header and used for the filename if not otherwise specified  |


### ⚙️ **Execution Configuration**

| Parameter      | Required | Default  | Description                                                                                                                      |
| -------------- | :------: | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `-profile`     |     ✓    | –        | Execution profile (`docker` or `singularity`).                                                             |
| `--max_memory` |     ✓    | `128.GB` | Maximum memory allocation.                                                                                                       |
| `--max_cpus`   |     ✓    | `16`     | Maximum CPUs allowed.                                                                                                            |
| `--max_time`   |     ✓    | `24.h`   | Maximum execution time.                                                                                                          |
| `-resume`      |     –    | –        | Reuse cached results from previous runs when inputs and code haven't changed. Ideal for interrupted runs. |

More NextFlow configuration options [`here`](https://www.nextflow.io/docs/latest/reference/config.html).


## 📊 Output overview

Results are structured by **species** inside `<outdir>/<Species>/`.
Each folder includes:

* **Snippy** results
* **Linkages** files
* **Panaroo** files
* **Gubbins** distance and cluster files
* **MashTree** files

Details about outputs can be found in [`output.md`](docs/output.md) and the outputs tree in [`poodle_outputs.md`](docs/poodle_outputs.md).

---

## 🔑 Key output files

PoODLE generates several output files to support surveillance and linkage interpretation.

### **📘 Genomic linkages**

File: `<Species>_<cluster_id>_<snippy/gubbins>_linkages.csv`

Identifies **strong** or **intermediate** linkages between samples based on **SNP distances**.

**Columns:**

* `sample`
* `species`
* `cluster_id`
* `min_dist`  — Minimum SNP distance
* `strong_linkages` — highly similar isolates (0-10)
* `intermediate_linkage` — moderately similar isolates (11-40)

---

### **📗 Reference evaluation**

File: `<Species>_<cluster_id>_reference_evaluation.tsv`

Aids to verify the reference selection for the samples in the cluster. A bad reference can result in core-genome shrinkage and obscure the genomic relationships. If a sample in the cluster differs too much from the reference it may show Fair or Poor alignment quality, in this case you can decide to either exclude the sample from the cluster or use a different reference; in other cases if most of the samples have low genome fraction, it'll be recommended to use a different reference.

  **Columns:**

  * `sample`
  * `genome_fraction`  — Percentage of the reference genome length aligned
  * `alignment_quality` — Excellent (>=98), Very Good (>= 95), Good (>= 85), Fair (>= 75), Poor (<75)

> [!TIP]
> Using an internal reference (one of the samples from the cluster) is a good practice and helps to avoid core-genome shrinkage.

### **📗 HTML report**

File: `<Species>_<cluster_id>.html`
This file provides a full overview of the results including interactive trees with phylocanvas, heatmap with pangenome profile, distance matrices (core SNPs, recombination-filtered SNPs, gene). These figures are interactive and allow easier interpretation of genomic relationships within the cluster.

---

## 🧭 Best practices & caveats

* **Use high-quality sequences:** Ideally, assemblies should have **<500 contigs ≥500 bp**, reads **≥30× Illumina coverage**, and **no contamination**. Pipelines like PHoeNIX, Bactopia and TheiaProk provide quality checks.

* **Disk cleanup:** After the pipeline completes, you may safely remove the Nextflow `work/` directory to reclaim space.

---

## 💬 Citations

If you use PoODLE, please cite:

* Snippy — SNP calling
* Panaroo — pangenome analysis
* Mashtree — composition-based tree
* Gubbins — genome recombination filtering
* snp-dists —  SNP distance calculation
* snp-sites —  AGTC position extractions
* IQ-TREE —  phylogeny
* nf-core — bioinformatics pipeline framework
* NextFlow — computational workflow
* Software packaging/containerization tools

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

---

## Credits & Community

PoODLE was built and is maintained by the Genomics Analysis Unit at the Michigan Department of Health & Human Services (MDHHS). This pipeline was developed by [Karla Vasco](https://github.com/vascokarla) and [Douglas Maldonado-Torres](https://github.com/MTDouglas).

📢 Contributions, issues, and pull requests are welcome — help make bacterial surveillance reproducible and accessible for everyone!

---

## 📜 License

This project is released under the [**MIT License**](LICENSE).
