process CONSTANTSITES {
    tag "$meta.species"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snp-sites:2.5.1--hed695b0_0' :
        'biocontainers/snp-sites:2.5.1--hed695b0_0' }"

    input:
    tuple val(meta), path(msa)

    output:
    tuple val(meta), path("${meta.species}_${meta.cluster_id}_constant-sites.txt"), emit: constant_sites

    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    snp-sites \\
        $msa \\
        -C \\
        $args \\
        > ${species}_${cluster_id}_constant-sites.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsites: \$(snp-sites -V 2>&1 | sed 's/snp-sites //')
    END_VERSIONS
    """
}

