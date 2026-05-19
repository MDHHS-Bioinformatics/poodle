process RENAME_ANNOTATION {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(meta), path(reads), path(assembly), path(annotation), path(reference)

    output:
    tuple val(meta), path(reads), path(assembly), path("renamed_files/${meta.id}.g*"), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    rename_inputs.py \
        --prefix $prefix \
        --annotation $annotation \
        --annotation_format ${params.annotation_format}
    """
}
