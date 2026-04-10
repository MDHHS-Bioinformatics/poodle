# 🚀 Pipeline Usage

This page describes how to run **PoODLE** and prepare the required input files.

Detailed descriptions of pipeline parameters can be found in
➡ **[`parameters.md`](parameters.md)**

## Table of contents
- [Recommended upstream step](#-recommended-upstream-step-defining-clusters-with-corge)
- [Quick start](#-quick-start)
  1. [Requirements](#1%EF%B8%8F%E2%83%A3-requirements)
  2. [Prepare the samplesheet](#2%EF%B8%8F%E2%83%A3-prepare-the-samplesheet)
  3. [Running the Pipeline](#-running-the-pipeline)
- [Pipeline Outputs](#-pipeline-outputs)
- [Best practices & caveats](#-best-practices--caveats)
- [Reproducibility](#-reproducibility)
- [Updating the Pipeline](#-updating-the-pipeline)

---

## 🔎 Recommended upstream step: defining clusters with CorGe+
<img src="./images/corge_poodle.png" alt="CorGe PoODLE" width="200" align="right"/>

Before running PoODLE, we **strongly recommend** identifying clusters (genomic context groups) using [**CorGe+**](https://github.com/MDHHS-Bioinformatics/corge). PoODLE is designed for **high-resolution analysis of *pre-defined* clusters**, not for initial large-scale clustering. Running PoODLE on poorly defined or overly broad groups can:

* obscure true transmission signals
* reduce core genome size
* increase computational cost
* complicate epidemiological interpretation

[**CorGe+**](https://github.com/MDHHS-Bioinformatics/corge) is optimized for **speed, scale, and screening**, while PoODLE provides **fine-grained, high-resolution analysis**.

Together, they form a **two-stage surveillance workflow**:

| Step | Tool       | Purpose                                             |
| ---- | ---------- | --------------------------------------------------- |
| 1    | **CorGe+** | Rapid screening and cluster detection               |
| 2    | **PoODLE** | Detailed SNP, recombination filtering, and pangenome analysis |


---

# PoODLE usage

## 1️⃣ Requirements

Install the following software:

* [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (≥ 22.10.1)
* A container runtime:

  * [`Docker`](https://docs.docker.com/engine/installation/) (recommended for local runs)
  * [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)
  * [`Apptainer`](https://apptainer.org/docs/user/latest/) (recommended for HPC)

> [!NOTE]  
> If using **Singularity** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_SINGULARITY_CACHEDIR="/path/to/singularity_cache"
> ``````
>
> If using **Apptainer** set `NXF_APPTAINER_CACHEDIR` (or `apptainer.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_APPTAINER_CACHEDIR="/path/to/apptainer_cache"
> ``````

---

## 2️⃣ Prepare the samplesheet

The pipeline requires a **CSV samplesheet** describing the samples to analyze.

Specify the file using:

```bash
--input samplesheet.csv
```

Each row corresponds to **one isolate/sample**.

---

### 📥 Samplesheet Specification

The samplesheet must contain **8 columns** with the following headers.

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Unique sample identifier. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina QC trimmed short reads 1. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`.                                                  |
| `fastq_2` | Full path to FastQ file for Illumina QC trimmed short reads 2. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`.                                                  |
| `annotation`     | Full path to file with annotated genomes. File should have the extension `.gff`, `.gff3`,`.gbk`, `.gb`, `.gbff`.                                                                                        |
| `assembly` | Full path to assembled genome file. File can be gzipped and have the extension `.fasta`, `.fa`, `.fna`, `.fasta.gz`, `.fa.gz` or .`fna.gz`|
| `cluster_id` | Custom cluster id. This entry will be identical for multiple samples from the same cluster. Spaces in cluter ids are automatically converted to underscores (`_`).                  |
| `species`  | Custom bacterial species name. This entry will be identical for multiple samples from the same species. Spaces in sample names are automatically converted to underscores (`_`).      |
| `reference` | Full path to assembled reference genome file. This must be identical for multiple samples from the same cluster. File can be gzipped and have the extension `.fasta`, `.fa`, `.fna`, `.fasta.gz`, `.fa.gz` or .`fna.gz`                                |

---

## Supported input types

_Supported input types for variant calling_

The pipeline supports three types of input data for variant calling:

| Input type       | Required columns     |
| ---------------- | -------------------- |
| Paired-end reads | `fastq_1`, `fastq_2` |
| Single-end reads | `fastq_1`            |
| Assemblies only  | `assembly`           |

If FASTQ files are not available, leave the columns blank.

> [!IMPORTANT]
> All columns must still be present in the CSV file.

_Supported annotation types for pangenome profiling_
Different annotation formats are supported by `Panaroo` for pangenome analysis.
If your annotations are not standard GFF3 files with embedded FASTA sequences, use the `--annotation_format` parameter to specify the correct format.

| Annotation file type             | Description                                                                              | `--annotation_format` |
| -------------------------------- | ---------------------------------------------------------------------------------------- | --------------------- |
| GFF3                             | GFF3 file with embedded FASTA (e.g. Prokka/Bakta output)                                 | `gff` (default)       |
| GFF3 + FASTA                     | GFF3 file without embedded FASTA, with a separate assembly FASTA file (e.g. NCBI RefSeq) | `split_gff`           |
| GenBank (`.gb`, `.gbk`, `.gbff`) | GenBank flat file containing both annotation and sequence                                | `genbank`             |

> [!IMPORTANT]
> All samples within a run must use the same annotation format.

> [!TIP]
> If you downloaded annotations from NCBI, you likely need `--annotation_format split_gff` or `genbank`.


## Example samplesheet

```csv
sample,fastq_1,fastq_2,annotation,assembly,cluster_id,species,reference
SAMPLE_1,/path/S1_R1.fastq.gz,/path/S1_R2.fastq.gz,/path/S1.gff,/path/S1.fasta,HC1-C1,Escherichia_coli,/path/ref1.fasta
SAMPLE_2,/path/S2_R1.fastq.gz,/path/S2_R2.fastq.gz,/path/S2.gff,/path/S2.fasta,HC1-C1,Escherichia_coli,/path/ref1.fasta
SAMPLE_3,/path/S3.fastq.gz,,/path/S3.gff,/path/S3.fasta,outbreak_A,Pseudomonas_aeruginosa,/path/ref2.fasta
SAMPLE_4,,,/path/S4.gff,/path/S4.fasta,outbreak_A,Pseudomonas_aeruginosa,/path/ref2.fasta
```

An example samplesheet is available in [`assets/samplesheet.csv`](../assets/samplesheet.csv)

---

# ▶ Running the Pipeline

## Basic run

```bash
nextflow run MDHHS-Bioinformatics/poodle \
  -profile singularity \
  --input samplesheet.csv \
  --outdir poodle_results
```

This will execute the core analysis workflow which include variant calling and pangenome analysis.

>[!NOTE]
>This command downloads this pipeline to `~/.nextflow/assets/MDHHS-Bioinformatics/poodle`. You can download the pipeline in a different location using `git clone https://github.com/MDHHS-Bioinformatics/poodle.git`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/poodle ...`).

---

## Advanced run

Example enabling optional analyses (recombination filtering with Gubbins and MashTree) and adjusting resources:

```bash
nextflow run MDHHS-Bioinformatics/poodle \
  -profile singularity \
  --input samplesheet.csv \
  --outdir poodle_results \
  --gubbins \
  --mashtree \
  --max_memory 50.GB \
  --max_cpus 16 \
  --max_time 8.h
```

---

# 📂 Pipeline Outputs

The pipeline produces the following directories:

```
work/          # Nextflow working directory
results/       # Final pipeline outputs
.nextflow.log  # Execution log
```

The `work/` directory contains intermediate files and may be deleted after successful completion.


For more details about the output files and reports, please refer to the [`Output documentation`](output.md)

---

# 🧠 Best practices & caveats

* **Use high-quality sequences:** Ideally, assemblies should have **<500 contigs ≥500 bp**, reads **≥30× Illumina coverage**, and **no contamination**. Pipelines like [`PHoeNIX`](https://github.com/CDCgov/phoenix), [`Bactopia`](https://bactopia.github.io/latest/) and [`TheiaProk`](https://public-health-bacterial-genomics-theiagen.readthedocs.io/en/latest/theiaprok.html) provide quality checks.

* **Disk cleanup:** After the pipeline completes, you may safely remove the Nextflow `work/` directory to reclaim space.

* Prefer **reads over assemblies** for SNP analysis
* Use **internal references** whenever possible
* Run with `--gubbins` for highly recombinant species
* Interpret SNP thresholds **in epidemiological context**, not in isolation
* A genomic cluster should contain > 4 closely related samples. We strongly recommend using PoODLE after [`CorGe+`](https://github.com/MDHHS-Bioinformatics/corge), since CorGe+ identifies genomic context groups at different thresholds.


# 🔁 Reproducibility

For reproducible analyses, run a specific pipeline release:

```bash
nextflow run MDHHS-Bioinformatics/poodle \
  -r v1.0.0 \
  -profile singularity \
  --input samplesheet.csv \
  --outdir results
```

Using version tags ensures the same pipeline code and container versions are used.

---

# 🔄 Updating the Pipeline

Nextflow caches pipeline code locally.

To update to the latest version:

```bash
nextflow pull MDHHS-Bioinformatics/poodle
```

