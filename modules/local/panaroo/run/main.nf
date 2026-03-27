process PANAROO_RUN {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/panaroo:1.6.0--pyhdfd78af_0'

    input:
    tuple val(meta), path(annotation_files), val(input_lines)

    output:
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_gene_presence_absence_roary.csv")            , emit: csv
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_gene_presence_absence.Rtab")                 , emit: rtab
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_summary_statistics.txt")                     , emit: summary
    path "versions.yml"                                                                                            , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def quoted_lines = input_lines.collect { "\"${it}\"" }.join(' ')
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    printf "%s\\n" ${quoted_lines} > panaroo_inputs.txt
    
    panaroo \\
        $args \\
        -t $task.cpus \\
        -o panaroo \\
        --clean-mode strict \\
        --remove-invalid-genes \\
        --threshold 0.98 \\
        --family_threshold 0.7 \\
        --core_threshold 0.99 \\
        -i panaroo_inputs.txt

    # Rename with species and cluster prefix
    for f in panaroo/*; do
        base=\$(basename "\$f")
        mv "\$f" "panaroo/${prefix}_\${base}"
    done


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        panaroo: \$(echo \$(panaroo --version 2>&1) | sed 's/^.*panaroo //' )
    END_VERSIONS
    """
}
