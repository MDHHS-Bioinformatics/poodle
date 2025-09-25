process CLEAN_TREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'

    conda "conda-forge::r-phytools=0.7_47"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phytools:0.6_99--r40h6115d3f_1' :
        'quay.io/biocontainers/r-phytools:0.6_44' }"

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
    Rscript -e "library(phytools); \
    tree <- read.tree('${tree}'); \
    midpoint_tree <- midpoint.root(tree); \
    midpoint_tree <- drop.tip(midpoint_tree, 'Reference'); \
    midpoint_tree <- ladderize(midpoint_tree, right = F); \
    write.tree(midpoint_tree, file='${prefix}${args_extension}.tre')"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | sed -n 's/^R version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
