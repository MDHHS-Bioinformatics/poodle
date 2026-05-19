process CLEAN_TREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'

    container 'quay.io/mdhhs_bioinformatics/quarto-wgs-reporting@sha256:2a3c9d9a87796ff612cce94e7638d906a04aec850ca0358446a3d5415526b326'
    // 'quay.io/mdhhs_bioinformatics/quarto-wgs-reporting:1.0.0'

    input:
    tuple val(meta), path(tree)

    output:
    tuple val(meta), path('*.tre')       , emit: tre
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args_extension = task.ext.args_extension ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    clean_tree.R '${tree}' '${prefix}${args_extension}.tre' 50

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | sed -n 's/^R version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
