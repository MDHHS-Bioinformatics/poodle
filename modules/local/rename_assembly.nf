process RENAME_ASSEMBLY {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(meta), path(reads), path(assembly), path(annotation), path(reference)

    output:
    tuple val(meta), path(reads), path("renamed_files/${meta.id}.fna"), path(annotation), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    //determine if we need to rename an assembly or not
    def assembly_input
    if (meta.has_assembly){
        assembly_input = "--assembly ${assembly}"
    } else{
        assembly_input = ""
    }

    """
    rename_inputs.py \\
        --prefix $prefix \\
        $assembly_input
    """
}
