process RENAME_REFERENCE {
    tag "$meta.id"
    label 'process_single'
    
    input:
    tuple val(meta), path(reference)

    output:
    tuple val(meta), path("${meta.species}_${meta.cluster_id}.fna") , emit: renamed_reference

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def ref_name = "${meta.species}_${meta.cluster_id}.fna"
    clusterid     = task.ext.prefix ?: "${meta.cluster_id}"
    species       = task.ext.prefix ?: "${meta.species}"

    """
    zcat -f "${reference}" > "${ref_name}"
    """
}
