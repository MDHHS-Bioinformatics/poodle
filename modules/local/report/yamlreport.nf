process YAML_REPORT {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_single'

    input:
    tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix), path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists), path(gubtree), path(gubmatrix), path(mashtree), path(mashmatrix)
    
    output:
    tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix), path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists), path(gubtree), path(gubmatrix), path(mashtree), path(mashmatrix), emit: files
    path("*.yaml"), emit: yaml

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    echo "cluster_id: ${meta.cluster_id}" > ${prefix}.yaml
    echo "species: ${meta.species}" >> ${prefix}.yaml
    echo "ref_eval: ${ref_eval}" >> ${prefix}.yaml
    echo "snptree: ${snptree}" >> ${prefix}.yaml
    echo "snpmatrix: ${snpmatrix}" >> ${prefix}.yaml
    echo "pan_summary: ${pan_summary}" >> ${prefix}.yaml
    echo "pan_roary: ${pan_roary}" >> ${prefix}.yaml
    echo "pan_rtab: ${pan_rtab}" >> ${prefix}.yaml
    echo "pan_genedists: ${pan_genedists}" >> ${prefix}.yaml
    echo "gubtree: ${gubtree}" >> ${prefix}.yaml
    echo "gubmatrix: ${gubmatrix}" >> ${prefix}.yaml
    echo "mashtree: ${mashtree}" >> ${prefix}.yaml
    echo "mashmatrix: ${mashmatrix}" >> ${prefix}.yaml

    """
}
