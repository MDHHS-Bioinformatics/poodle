process RENAME_REFERENCE {
    tag '$meta.id'
    label 'process_single'
    
    input:
    tuple val(meta), path(reference)

    output:
    tuple val(meta), path("${species}_${clusterid}.fna") , emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    clusterid = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    # Rename the reference file based on species and cluster id
    mv $reference ${species}_${clusterid}.fna

    """
}
