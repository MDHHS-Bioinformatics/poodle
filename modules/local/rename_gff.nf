process RENAME_GFF {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    //tuple val(meta), path(input_files), path(gff), path(reference)
    tuple val(meta), path(reads), path(assemblies), path(gff), path(reference)

    output:
    tuple val(meta), path(reads), path(assemblies), path("renamed_files/*.gff"), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    rename_inputs.py \\
        --prefix $prefix \\
        --gff $gff
    """
}
