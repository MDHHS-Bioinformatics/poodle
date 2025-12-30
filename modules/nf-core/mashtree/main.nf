process MASHTREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mashtree:1.4.6--pl5321h7b50bb2_3' :
        'quay.io/biocontainers/mashtree:1.4.6--pl5321h7b50bb2_3' }"
        
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
    //prefix = task.ext.prefix ?: "${meta.id}"
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

    stub:
    //prefix = task.ext.prefix ?: "${meta.id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    touch ${species}_${cluster_id}.dnd
    touch ${species}_${cluster_id}.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mashtree: \$( echo \$( mashtree --version 2>&1 ) | sed 's/^.*Mashtree //' )
    END_VERSIONS
    """
}
