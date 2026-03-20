process RENAME_GFF {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
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
