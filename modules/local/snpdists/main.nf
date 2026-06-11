process SNPDISTS {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/snp-dists@sha256:d6204b4fba8508d9531a69ee705c36756c79d1f8dc85e129e0908c1eaf19d3ac'
    // 'quay.io/biocontainers/snp-dists:1.2.0--h577a1d6_0'
     
    input:
    tuple val(meta), path(alignment)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args_extension = task.ext.args_extension ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    snp-dists \\
        $args \\
        $alignment > ${prefix}_${args_extension}dist.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpdists: \$(snp-dists -v 2>&1 | sed 's/snp-dists //;')
    END_VERSIONS
    """
}
