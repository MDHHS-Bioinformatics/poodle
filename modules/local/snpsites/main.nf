process SNPSITES {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/snp-sites@sha256:d19b090d52dc1d29b6f862e30cfc38f10fad8cb6954d76ef37298002e1a89213'
    // 'quay.io/biocontainers/snp-sites:2.5.1--h577a1d6_7'

    input:
    tuple val(meta), path(msa)

    output:
    tuple val(meta), path("${meta.species}_${meta.cluster_id}_snp-sites.fna"), emit: snp_fasta

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
        -c \\
        $args \\
        > ${species}_${cluster_id}_snp-sites.fna

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsites: \$(snp-sites -V 2>&1 | sed 's/snp-sites //')
    END_VERSIONS
    """
}

