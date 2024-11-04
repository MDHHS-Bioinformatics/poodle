process RENAME_INPUTS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(input_files), path(gff), path(reference)

    output:
    tuple val(meta), path("renamed_files/*"), path(gff), path(reference), emit:renamed_files
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    """
    mkdir -p renamed_files

    for file in ${input_files}; do
        if [[ "\$file" == *"_1."*".fastq.gz" ]]; then
            # Rename _1.fastq files
            newname="renamed_files/${prefix}_1.fastq.gz"
            cp "\$file" "\$newname"
        elif [[ "\$file" == *"_2."*".fastq.gz" ]]; then
            # Rename _2.fastq files
            newname="renamed_files/${prefix}_2.fastq.gz"
            cp "\$file" "\$newname"
        elif [[ "\$file" == *.fna ]]; then
            # Rename .fna files
            newname="renamed_files/${prefix}.fna"
            cp "\$file" "\$newname"
        else
            echo "Unrecognized file format for \$file" >&2
            exit 1
        fi
    done


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        renameinputs: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
