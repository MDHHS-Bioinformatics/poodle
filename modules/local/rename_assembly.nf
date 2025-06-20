process RENAME_ASSEMBLY {
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
    tuple val(meta), path(reads), path("renamed_files/*"), path(gff), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    //determine if we need to rename an assembly or not
    def assembly_input
    if (meta.has_assembly){
        assembly_input = "--assembly ${assemblies}"
    } else{
        assembly_input = ""
    }

    """
    rename_inputs.py \\
        --prefix $prefix \\
        $assembly_input
    """
}
