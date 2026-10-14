process ZERO_SNP_TREE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'
    
    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'
    
    input:
    tuple val(meta), path(snp_report)

    output:
    tuple val(meta), path("${meta.species}_${meta.cluster_id}.tre"), emit: tre
    path "versions.yml"                                            , emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    generate_zero_snp_tree.py \\
        --snp-report ${snp_report} \\
        --output ${prefix}.tre
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c 'import pandas; print(pandas.__version__)')
    END_VERSIONS
    """
}
