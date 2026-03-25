# ⚙️ Pipeline Parameters

This page documents all parameters available for **PoODLE**.

Pipeline parameters use **double hyphens (`--`)**, while Nextflow runtime options use **single hyphens (`-`)**.

Example:

```bash
nextflow run MDHHS-Bioinformatics/poodle \
  -profile singularity \
  --input samplesheet.csv \
  --outdir results
```

---

## 📥 Core Pipeline Parameters

These parameters are required for most pipeline runs.

| Parameter  | Type   | Required | Default     | Description                                                            |
| ---------- | ------ | -------- | ----------- | ---------------------------------------------------------------------- |
| `--input`  | string | ✓        | –           | Path to the input samplesheet (CSV) describing the samples to process. |
| `--outdir` | string | ✓        | `./poodle_results` | Directory where pipeline results will be written.               |
| `--email`  | string | –        | –           | Email address to receive pipeline completion notifications.            |
| `--annotation_format`  | string | ✓        | `gff`     | Format of the annotation files used for pangenome analysis. Options: `gff` (standard GFF3 with embedded FASTA by tools such as Prokka or Bakta), `split_gff` (for annotations lacking embedded FASTA sequences, e.g. RefSeq-style), or `genbank` (`.gbk`, `.gb`, `.gbff`). All samples in a run must use the same format.|

---

## 🧬 Analysis Options

These parameters enable optional analysis steps.

| Parameter            | Type    | Default | Description                                                        |
| -------------------- | ------- | ------- | ------------------------------------------------------------------ |
| `--gubbins`          | boolean | `false` | Perform recombination filtering using Gubbins.                     |
| `--mashtree`         | boolean | `false` | Generate an genomic composition tree using MashTree.               |
| `--previous_results` | string  | –       | Path to previous pipeline results used to reuse existing analyses. By default, the pipeline looks for prior Snippy results for the same cluster in the outdir. |
| `--save_snippy_run`  | boolean | `true`  | Save Snippy run outputs for each sample.                           |
| `--logo_report`      | string  | `assets/DNA_logo.png`  | Logo in PNG format to include in the report header  |


---

## ⚙️ Execution Configuration

These parameters control compute resource limits.

| Parameter      | Type    | Default  | Description                                      |
| -------------- | ------- | -------- | ------------------------------------------------ |
| `--max_cpus`   | integer | `16`     | Maximum CPUs that can be requested by any job.   |
| `--max_memory` | string  | `128.GB` | Maximum memory that can be requested by any job. |
| `--max_time`   | string  | `24.h`   | Maximum execution time for any job.              |

---

## 🔧 Generic Pipeline Options

These parameters control pipeline behavior.

| Parameter              | Type    | Default | Description                              |
| ---------------------- | ------- | ------- | ---------------------------------------- |
| `--help`               | boolean | –       | Display help message and exit.           |
| `--version`            | boolean | –       | Print pipeline version and exit.         |
| `--validate_params`    | boolean | `true`  | Validate parameters against schema.      |
| `--show_hidden_params` | boolean | `false` | Show advanced parameters in help output. |
| `--monochrome_logs`    | boolean | `false` | Disable colored logging output.          |

---

## 🧠 Core Nextflow Arguments

These options are part of **Nextflow itself** and use a **single hyphen (`-`)**.

---

## `-profile`

Select the execution configuration profile.

Example:

```bash
-profile singularity
```

Available profiles typically include:

| Profile       | Description                         |
| ------------- | ----------------------------------- |
| `docker`      | Run using Docker containers         |
| `singularity` | Run using Singularity containers    |
| `apptainer`   | Run using Apptainer containers      |
| `test`        | Run pipeline with bundled test data |

Multiple profiles can be combined:

```bash
-profile test,singularity
```


---

## `-r` (Pipeline Release Version)

Specify the **pipeline version or Git revision** to run.

Example:

```bash
nextflow run MDHHS-Bioinformatics/poodle -r v1.0.0
```

This ensures that the **exact same pipeline version** is used for analysis.

You can also run:

| Example       | Description                        |
| ------------- | ---------------------------------- |
| `-r v1.0.0`   | Run a tagged release               |
| `-r main`     | Run the latest development version |
| `-r <commit>` | Run a specific Git commit          |

⚠️ For **reproducible analyses**, it is strongly recommended to run a **tagged release**.

---

## `-resume`

Resume a previously failed or interrupted pipeline run.

```bash
-resume
```

Nextflow will reuse cached results when possible.

---

## `-c`

Provide a custom Nextflow configuration file.

```bash
-c custom.config
```

---

## 🏛 Institutional Configuration Options

These parameters are used when loading configurations from [`nf-core/configs`](https://nf-co.re/configs/).

| Parameter                      | Description                                         |
| ------------------------------ | --------------------------------------------------- |
| `--custom_config_version`      | Git commit ID for institutional configs             |
| `--custom_config_base`         | Base URL for institutional configuration repository |
| `--config_profile_name`        | Name of institutional profile                       |
| `--config_profile_description` | Description of institutional profile                |
| `--config_profile_contact`     | Contact information                                 |
| `--config_profile_url`         | Documentation URL                                   |

---

## ⚡ Custom Configuration (Advanced)

Users can override pipeline resource requirements using custom configuration files.

Example:

```nextflow
process {
    withName: ALIGNMENT {
        memory = 100.GB
        cpus = 8
    }
}
```

Run with:

```bash
nextflow run poodle -c custom.config
```

---

## 🧰 Troubleshooting Resource Issues

If a job fails due to insufficient memory or CPUs, you can increase global resource limits:

```bash
--max_memory 200.GB \
--max_cpus 32 \
-resume
```
