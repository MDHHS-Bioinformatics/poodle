process MASHTREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/mashtree@sha256:eb96b6f479f0dc4fd5e655c27ba2ce55e94e63ca36e52132e84f76c6de047cdd'
    // 'quay.io/biocontainers/mashtree:1.4.6--pl5321h87e0c26_4'
        
    input:
    tuple val(meta), path(seqs)

    output:
    tuple val(meta), path("*.dnd"), emit: tree
    tuple val(meta), path("*.tsv"), emit: matrix
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    mashtree \\
        $args \\
        --numcpus $task.cpus \\
        --outmatrix ${species}_${cluster_id}.tsv \\
        --outtree ${species}_${cluster_id}.dnd \\
        $seqs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mashtree: \$( echo \$( mashtree --version 2>&1 ) | sed 's/^.*Mashtree //' )
    END_VERSIONS
    """
}
