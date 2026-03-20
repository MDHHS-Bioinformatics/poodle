process LINKAGES {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'
    
    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(meta), path(snp_dists), path(snp_report)

    output:
    tuple val(meta), path("*.csv"), emit: linkages
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args_extension = task.ext.args_extension ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    bacteria_linkage_snps.py \
        --species $species \
        --cluster-id $cluster_id \
        --snp-dists $snp_dists \
        --snp-report $snp_report \
        --output ${prefix}${args_extension}.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
