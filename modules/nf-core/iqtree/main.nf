process IQTREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.3.4--h21ec9f0_0' :
        'biocontainers/iqtree:2.3.4--h21ec9f0_0' }"

    input:
    tuple val(meta), path(alignment), val(constant_sites)

    output:
    tuple val(meta), path("*.treefile")      , emit: phylogeny     , optional: true
    tuple val(meta), path("*.iqtree")        , emit: report        , optional: true
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                     = task.ext.args           ?: ''
    def alignment_arg            = alignment               ? "-s $alignment": ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    def memory                      = task.memory.toString().replaceAll(' ', '')
    """
    iqtree \\
        $args \\
        $alignment_arg \\
        -fconst $constant_sites \\
        -pre $prefix \\
        -nt AUTO \\
        -safe \\
        -redo \\
        -m GTR+G4 \\
        -ntmax $task.cpus \\
        -mem $memory \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: meta.id
    """
    touch "${prefix}.treefile"
    touch "${prefix}.iqtree"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """

}
