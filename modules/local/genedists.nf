process GENEDISTS {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_low'
    
    conda "conda-forge::r-phytools=0.7_47"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phytools:0.6_99--r40h6115d3f_1' :
        'quay.io/biocontainers/r-phytools:0.6_44' }"

    input:
    tuple val(meta), path(rtab)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in MI-Bioinformatics/process-bact-cluster-per-species/bin/
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
