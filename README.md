# ![nf-core/processclusterperspecies](docs/images/nf-core-processclusterperspecies_logo_light.png#gh-light-mode-only) ![nf-core/processclusterperspecies](docs/images/nf-core-processclusterperspecies_logo_dark.png#gh-dark-mode-only)


[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)



## Introduction

<!-- TODO nf-core: Write a 1-2 sentence summary of what data the pipeline is for and what it does -->

**process-bact-cluster-per-species** is a bioinformatics best-practice analysis pipeline for phylogenetic analysis of bacterial clusters. This pipleine includes Snippy run, Snippy core, Gubbins (optional), Panaroo and MashTree (optional).

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

## Pipeline summary

1. Identify reference-based SNPs with [`Snippy`](https://github.com/tseemann/snippy)-run for each sample.
2. Make a core genome alignment with [`Snippy`](https://github.com/tseemann/snippy)-core, generate a SNP tree with [`IQ-TREE`](https://www.iqtree.org/) and calculate SNP distances with [`snp-dists`](https://github.com/tseemann/snp-dists).
3. Mask recombinant sites with [`Gubbins`](https://github.com/nickjcroucher/gubbins) and calculate SNP distances with [`snp-dists`](https://github.com/tseemann/snp-dists) (optional).
4. Pangenome profile (gene presence-absence) with [`Panaroo`](https://github.com/gtonkinhill/panaroo) and calculate gene distances.
5. Make a tree with Mash distances using [`MashTree`](https://github.com/lskatz/mashtree) (optional).
6. Summary results ([`MultiQC`](http://multiqc.info/))

![Pipeline Workflow](./processclusters-nf_flowchart.png)


## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Clone this repository and test it on a minimal dataset with a single command:

   ```bash
   nextflow run process-bact-clusters/main.nf -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

Prepare a manifest CSV file with paths to the trimmed FASTQ files, GFFs and assemblies:

| sample    | fastq_1                    | fastq_2                    | gff                  | assembly                       | reference                   | cluster_id | species      |
|-----------|----------------------------|----------------------------|----------------------|--------------------------------|-----------------------------|------------|--------------|
| sample_1  | /path/to/sample_1_R1.fastq.gz | /path/to/sample_1_R2.fastq.gz | /path/to/sample_1.gff | /path/to/sample_1_assembly.fasta | /path/to/sample_1_reference.fasta | cluster_1  | species_1    |
| sample_2  | /path/to/sample_2_R1.fastq.gz | /path/to/sample_2_R2.fastq.gz | /path/to/sample_2.gff | /path/to/sample_2_assembly.fasta | /path/to/sample_2_reference.fasta | cluster_2  | species_2    |
| sample_3  | /path/to/sample_3_R1.fastq.gz | /path/to/sample_3_R2.fastq.gz | /path/to/sample_3.gff | /path/to/sample_3_assembly.fasta | /path/to/sample_3_reference.fasta | cluster_3  | species_3    |
| sample_4  | /path/to/sample_4_R1.fastq.gz | /path/to/sample_4_R2.fastq.gz | /path/to/sample_4.gff | /path/to/sample_4_assembly.fasta | /path/to/sample_4_reference.fasta | cluster_4  | species_4    |
| sample_5  | /path/to/sample_5_R1.fastq.gz | /path/to/sample_5_R2.fastq.gz | /path/to/sample_5.gff | /path/to/sample_5_assembly.fasta | /path/to/sample_5_reference.fasta | cluster_5  | species_5    |



   ```bash
   nextflow run process-bact-clusters/main.nf --input manifest.csv --outdir <OUTDIR> --reference <REFERENCE.fasta> --cluster_id <CLUSTER> --gubbins --mashtree -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>
   ```

## Credits

process-bact-clusters was originally written by MDHHS Genomics Analysis Unit with Karla Vasco and Douglas Maldonado-Torres as main mainteiners.


## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
