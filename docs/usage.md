# MI-Bioinformatics/poodle: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

## Samplesheet input

You will need to create a samplesheet also known as manifest with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 8 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

Create a CSV file containing paths to the following: QC-trimmed FASTQ files, GFFs, assemblies, cluster_id, species, and reference. Snippy supports inputs in three formats: paired-end reads, single-end reads, or assemblies. 

- **Paired-end reads**: Include paths for both `fastq_1` and `fastq_2`.
- **Single-end reads**: Leave the `fastq_2` column blank.
- **Assemblies only**: Leave both `fastq_1` and `fastq_2` columns blank.

The following columns are **mandatory**:
- `sample`
- `gff`
- `assembly`
- `cluster_id`
- `species`
- `reference`


### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet. The samplesheet can have as many columns as you desire, however, there is a strict requirement for the first 3 columns to match those defined in the table below.

A final samplesheet file consisting of either single-end, paired-end or assembly data may look something like the one below. This is for 7 samples, where two species and cluster_ids are included.

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

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina QC trimmed short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                  |
| `fastq_2` | Full path to FastQ file for Illumina QC trimmed short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                  |
| `gff`     | Full path to GFF file with annotated genomes. File should have the extension ".gff" or ".gff3".                                                                                        |
| `assembly` | Full path to assembled genome file. File can be gzipped and have the extension ".fasta", ".fa", ".fna", ".fasta.gz", ".fa.gz" or ".fna.gz"                                            |
| `cluster_id` | Custom cluster id. This entry will be identical for multiple samples from the same cluster. Spaces in cluter ids are automatically converted to underscores (`_`).                  |
| `species`  | Custom bacterial species name. This entry will be identical for multiple samples from the same species. Spaces in sample names are automatically converted to underscores (`_`).      |
| `reference` | Full path to assembled reference genome file. This must be identical for multiple samples from the same cluster. File can be gzipped and have the extension ".fasta", ".fa", ".fna", ".fasta.gz", ".fa.gz" or ".fna.gz"                                 |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run MI-Bioinformatics/poodle --input samplesheet.csv --outdir <OUTDIR> --gubbins --mashtree -profile singularity
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull MI-Bioinformatics/poodle
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [MI-Bioinformatics/poodle releases page](https://github.com/MI-Bioinformatics/poodle/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter or Charliecloud.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

For example, if the nf-core/rnaseq pipeline is failing after multiple re-submissions of the `STAR_ALIGN` process due to an exit code of `137` this would indicate that there is an out of memory issue:

```console
[62/149eb0] NOTE: Process `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)` terminated with an error exit status (137) -- Execution is retried (1)
Error executing process > 'NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)'

Caused by:
    Process `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)` terminated with an error exit status (137)

Command executed:
    STAR \
        --genomeDir star \
        --readFilesIn WT_REP1_trimmed.fq.gz  \
        --runThreadN 2 \
        --outFileNamePrefix WT_REP1. \
        <TRUNCATED>

Command exit status:
    137

Command output:
    (empty)

Command error:
    .command.sh: line 9:  30 Killed    STAR --genomeDir star --readFilesIn WT_REP1_trimmed.fq.gz --runThreadN 2 --outFileNamePrefix WT_REP1. <TRUNCATED>
Work dir:
    /home/pipelinetest/work/9d/172ca5881234073e8d76f2a19c88fb

Tip: you can replicate the issue by changing to the process work dir and entering the command `bash .command.run`
```

#### For beginners

A first step to bypass this error, you could try to increase the amount of CPUs, memory, and time for the whole pipeline. Therefor you can try to increase the resource for the parameters `--max_cpus`, `--max_memory`, and `--max_time`. Based on the error above, you have to increase the amount of memory. Therefore you can go to the [parameter documentation of rnaseq](https://nf-co.re/rnaseq/3.9/parameters) and scroll down to the `show hidden parameter` button to get the default value for `--max_memory`. In this case 128GB, you than can try to run your pipeline again with `--max_memory 200GB -resume` to skip all process, that were already calculated. If you can not increase the resource of the complete pipeline, you can try to adapt the resource for a single process as mentioned below.

#### Advanced option on process level

To bypass this error you would need to find exactly which resources are set by the `STAR_ALIGN` process. The quickest way is to search for `process STAR_ALIGN` in the [nf-core/rnaseq Github repo](https://github.com/nf-core/rnaseq/search?q=process+STAR_ALIGN).
We have standardised the structure of Nextflow DSL2 pipelines such that all module files will be present in the `modules/` directory and so, based on the search results, the file we want is `modules/nf-core/star/align/main.nf`.
If you click on the link to that file you will notice that there is a `label` directive at the top of the module that is set to [`label process_high`](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/modules/nf-core/software/star/align/main.nf#L9).
The [Nextflow `label`](https://www.nextflow.io/docs/latest/process.html#label) directive allows us to organise workflow processes in separate groups which can be referenced in a configuration file to select and configure subset of processes having similar computing requirements.
The default values for the `process_high` label are set in the pipeline's [`base.config`](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L33-L37) which in this case is defined as 72GB.
Providing you haven't set any other standard nf-core parameters to **cap** the [maximum resources](https://nf-co.re/usage/configuration#max-resources) used by the pipeline then we can try and bypass the `STAR_ALIGN` process failure by creating a custom config file that sets at least 72GB of memory, in this case increased to 100GB.
The custom config below can then be provided to the pipeline via the [`-c`](#-c) parameter as highlighted in previous sections.

```nextflow
process {
    withName: 'NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN' {
        memory = 100.GB
    }
}
```

> **NB:** We specify the full process name i.e. `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN` in the config file because this takes priority over the short name (`STAR_ALIGN`) and allows existing configuration using the full process name to be correctly overridden.
>
> If you get a warning suggesting that the process selector isn't recognised check that the process name has been specified correctly.

### Updating containers (advanced users)

The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. If for some reason you need to use a different version of a particular tool with the pipeline then you just need to identify the `process` name and override the Nextflow `container` definition for that process using the `withName` declaration. For example, in the [nf-core/viralrecon](https://nf-co.re/viralrecon) pipeline a tool called [Pangolin](https://github.com/cov-lineages/pangolin) has been used during the COVID-19 pandemic to assign lineages to SARS-CoV-2 genome sequenced samples. Given that the lineage assignments change quite frequently it doesn't make sense to re-release the nf-core/viralrecon everytime a new version of Pangolin has been released. However, you can override the default container used by the pipeline by creating a custom config file and passing it as a command-line argument via `-c custom.config`.

1. Check the default version used by the pipeline in the module file for [Pangolin](https://github.com/nf-core/viralrecon/blob/a85d5969f9025409e3618d6c280ef15ce417df65/modules/nf-core/software/pangolin/main.nf#L14-L19)
2. Find the latest version of the Biocontainer available on [Quay.io](https://quay.io/repository/biocontainers/pangolin?tag=latest&tab=tags)
3. Create the custom config accordingly:

   - For Docker:

     ```nextflow
     process {
         withName: PANGOLIN {
             container = 'quay.io/biocontainers/pangolin:3.0.5--pyhdfd78af_0'
         }
     }
     ```

   - For Singularity:

     ```nextflow
     process {
         withName: PANGOLIN {
             container = 'https://depot.galaxyproject.org/singularity/pangolin:3.0.5--pyhdfd78af_0'
         }
     }
     ```

   - For Conda:

     ```nextflow
     process {
         withName: PANGOLIN {
             conda = 'bioconda::pangolin=3.0.5'
         }
     }
     ```

> **NB:** If you wish to periodically update individual tool-specific results (e.g. Pangolin) generated by the pipeline then you must ensure to keep the `work/` directory otherwise the `-resume` ability of the pipeline will be compromised and it will restart from scratch.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure Resource Requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Input/Output Options
- `--input`                       [string]  Path to comma-separated file containing information about the samples and reference in the analysis (mandatory).
- `--outdir`                      [string]  The output directory where the results will be saved. You must use absolute paths for storage on Cloud infrastructure (mandatory).  
- `--gubbins`                     [boolean] Filter out recombinant sites with Gubbins (optional).
- `--mashtree`                    [boolean] Analyze genomic distances and generate a tree with MashTree (optional).
- `--previous_results`            [string]  Path to previous results. By default, the pipeline looks for prior Snippy results for the same cluster in the outdir (optional). 
- `--save_snippy_run`             [boolean] Do not publish Snippy run results. By default, the pipeline saves the Snippy-run results per sample (optional).
- `--email`                       [string]  Email address for completion summary (optional).
- `--multiqc_title`               [string]  MultiQC report title. Printed as a page header and used for the filename if not otherwise specified (optional).

### Institutional Config Options
- `--custom_config_version`       [string]  Git commit ID for institutional configs. [default: master]
- `--custom_config_base`          [string]  Base directory for institutional configs. [default: https://raw.githubusercontent.com/nf-core/configs/master]
- `--config_profile_name`         [string]  Institutional config name.
- `--config_profile_description`  [string]  Institutional config description.
- `--config_profile_contact`      [string]  Institutional config contact information.
- `--config_profile_url`          [string]  Institutional config URL link.

### Max Job Request Options
- `--max_cpus`                    [integer] Maximum number of CPUs that can be requested for any single job. [default: 16]
- `--max_memory`                  [string]  Maximum amount of memory that can be requested for any single job. [default: 128.GB]
- `--max_time`                    [string]  Maximum amount of time that can be requested for any single job. [default: 240.h]

### Generic Options
- `--help`                        [boolean] Display help text.
- `--version`                     [boolean] Display version and exit.
- `--publish_dir_mode`            [string]  Method used to save pipeline results to the output directory. [default: copy]
- `--email_on_fail`               [string]  Email address for completion summary, only when the pipeline fails.
- `--plaintext_email`             [boolean] Send plain-text email instead of HTML.
- `--max_multiqc_email_size`      [string]  File size limit when attaching MultiQC reports to summary emails. [default: 25.MB]
- `--monochrome_logs`             [boolean] Do not use colored log outputs.
- `--hook_url`                    [string]  Incoming hook URL for messaging service.
- `--multiqc_config`              [string]  Custom config file to supply to MultiQC.
- `--multiqc_logo`                [string]  Custom logo file to supply to MultiQC. The file name must also be set in the MultiQC config file.
- `--multiqc_methods_description` [string]  Custom MultiQC YAML file containing HTML including a methods description.
- `--tracedir`                    [string]  Directory to keep pipeline Nextflow logs and reports. [default: `${params.outdir}/pipeline_info`]
- `--validate_params`             [boolean] Whether to validate parameters against the schema at runtime [default: true].
- `--show_hidden_params`          [boolean] Show all params when using `--help`.
