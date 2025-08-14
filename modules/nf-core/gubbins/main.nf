process GUBBINS {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'
    
    errorStrategy 'ignore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gubbins:3.3.5--py39pl5321he4a0461_0' :
        'biocontainers/gubbins:3.3.5--py39pl5321he4a0461_0' }"

    input:
    tuple val(meta), path(msa), val(constant_sites)

    output:
    tuple val(meta), path("*.fasta")                             , emit: fasta
    tuple val(meta), path("*.gff")                               , emit: gff
    tuple val(meta), path("*.vcf")                               , emit: vcf
    tuple val(meta), path("*.csv")                               , emit: stats
    tuple val(meta), path("*.phylip")                            , emit: phylip
    tuple val(meta), path("*.recombination_predictions.embl")    , emit: embl_predicted
    tuple val(meta), path("*.branch_base_reconstruction.embl")   , emit: embl_branch
    tuple val(meta), path("*.final_tree.tre")                    , emit: tree
    tuple val(meta), path("*.node_labelled.final_tree.tre")      , emit: tree_labelled
    tuple val(meta), path("*.final_bootstrapped_tree.tre")       , emit: bootstrap_tree, optional: true
    path "versions.yml"                                          , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    mkdir numba_cache_dir
    export NUMBA_CACHE_DIR='./numba_cache_dir'
    
    run_gubbins.py \\
        --threads $task.cpus \\
        --prefix $prefix \\
        --first-tree-builder iqtree-fast \\
        --tree-builder iqtree \\
        --tree-args " -fconst $constant_sites" \\
        $args \\
        $msa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(run_gubbins.py --version 2>&1)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    mkdir numba_cache_dir
    export NUMBA_CACHE_DIR='./numba_cache_dir'

    touch ${alignment.baseName}.fasta
    touch ${alignment.baseName}.gff
    touch ${alignment.baseName}.vcf
    touch ${alignment.baseName}.csv
    touch ${alignment.baseName}.phylip
    touch ${alignment.baseName}.recombination_predictions.embl
    touch ${alignment.baseName}.branch_base_reconstruction.embl
    touch ${alignment.baseName}.final_tree.tre
    touch ${alignment.baseName}.node_labelled.final_tree.tre

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(run_gubbins.py --version 2>&1)
    END_VERSIONS
    """
}
