# 🧬 Pipeline Workflow

This document describes the analytical workflow implemented in **PoODLE**.

The pipeline processes sequencing data using a series of modular steps implemented in **Nextflow DSL2**. Each step is executed independently and automatically parallelized when possible.

---

# 📊 Workflow Overview

The workflow consists of several stages that transform sequencing data into interpretable results for genomic surveillance and linkage investigation.

![Pipeline Workflow](./images/poodle_flow.png)

---

# 🔬 Pipeline Stages

## 1️⃣ Variant Calling
1. **Reference-based SNP calling (Snippy)**
   * Runs [`Snippy`](https://github.com/tseemann/snippy) per sample within each cluster
   * Automatically detects if results already exist
   * **Reuses previous results** when the same reference was used
     → *This is critical for surveillance workflows where clusters grow over time*

2. **Core genome alignment & SNP distances**
   * [`Snippy`](https://github.com/tseemann/snippy) builds the core genome alignment
   * [`IQ-TREE`](https://www.iqtree.org/) builds a phylogeny with the GTR+G4 model
   * [`snp-dists`](https://github.com/tseemann/snp-dists) calculates pairwise SNP distances

---

## 2️⃣ Recombination Filtering *(Optional)*

Recombination events can distort phylogenetic inference. When enabled, recombinant regions are identified and removed.
   * [`Gubbins`](https://github.com/nickjcroucher/gubbins) masks recombinant regions
   * SNP-only alignment is rebuilt with [`snp-sites`](https://sanger-pathogens.github.io/snp-sites/)
   * Phylogenetic tree and SNP distances are generated
   
## 3️⃣ Pangenome Analysis

Gene presence and absence across genomes is analyzed with [`Panaroo`](https://github.com/gtonkinhill/panaroo) to characterize genomic diversity. Hamming distances based on gene presence are calculated as a metric to compare genome similarity including accessory genes.


##  4️⃣ MashTree *(Optional)*

A rapid whole-genome comparison can be performed using assembly-based distance estimation with [`MashTree`](https://github.com/lskatz/mashtree).

## 5️⃣ Reporting

Results from all analysis steps are summarized into an interactive report made with Quarto and several R packages including [`phylocanvas`](https://www.phylocanvas.gl/), [`plottly`](https://plotly.com/) and [`tidyverse`](https://tidyverse.org/).

Outputs include:

* cluster-specific HTML reports
* phylogenetic trees
* SNP and gene distance matrices
* pangenome visualizations
* linkage classification tables

These reports are designed for **epidemiological interpretation and outbreak investigation**.
