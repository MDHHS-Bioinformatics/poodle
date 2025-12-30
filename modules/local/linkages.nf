process LINKAGES {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'

    container "quay.io/vascok/quarto-wgs-reporting:1.0.0"

    input:
    tuple val(meta), path(core_dists), path(core_dists)

    output:
    tuple val(meta), path('*.csv')       , emit: tre
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args_extension = task.ext.args_extension ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    linkages.R \
        --species $species \
        --cluster_id $cluster_id \
        --dist $dist \
        --output ${prefix}${args_extension}.csv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | sed -n 's/^R version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
