process GENEDISTS {
    tag '$meta.species'
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-base%3A4.4.1' :
        'quay.io/biocontainers/r-base:4.4.1' }"

    input:
    tuple val(meta), path(rtab)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    # Calculate gene presence-absence Hamming distances
    gene_dists.R ${rtab} gene_presence_absence_dist.tsv

    # Capture the R version for versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | head -n 1 | sed 's/R version //')
    END_VERSIONS
    """
}
