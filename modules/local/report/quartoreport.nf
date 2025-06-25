process QUARTO_REPORT {
    tag "$meta.species"
    label 'process_medium'

    //conda "${moduleDir}/environment.yml"
    container "r-quarto-phylo.sif"
    // For Docker
    //docker.containerOptions = '-u $(id -u):$(id -g) -e USERID=$UID -e XDG_CACHE_HOME=tmp/quarto_cache_home -e XDG_DATA_HOME=tmp/quarto_data_home -e QUARTO_PRINT_STACK=true'

    // For Singularity (separate config block)
    containerOptions = '--no-home --env USERID=$UID,XDG_CACHE_HOME=tmp/quarto_cache_home,XDG_DATA_HOME=tmp/quarto_data_home,QUARTO_PRINT_STACK=true'

    stageInMode = 'copy'
    afterScript = 'rm -rf tmp'

    input:
    tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix), path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists), path(gubtree), path(gubmatrix), path(mashtree), path(mashmatrix)
    path(yaml)
    path(qmd)
    path(logo)

    output:
    tuple val(meta), path("${meta.species}_${meta.cluster_id}.html"), emit: html
    path "versions.yml",    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    
    """
    cp -n ${ref_eval} .
    cp -n ${snptree} .
    cp -n ${snpmatrix} .
    cp -n ${pan_summary} .
    cp -n ${pan_roary} .
    cp -n ${pan_rtab} .
    cp -n ${pan_genedists} .
    cp -n ${gubtree} .
    cp -n ${gubmatrix} .
    cp -n ${mashtree} .
    cp -n ${mashmatrix} .
    cp -n ${logo} .
    
    quarto \\
            render \\
            $qmd \\
            --execute-params $yaml \\
            --output "${prefix}.html"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quarto: \$(quarto --version)
    END_VERSIONS
    """
}
