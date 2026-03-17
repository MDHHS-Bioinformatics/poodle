process PANAROO_RUN {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/panaroo:1.5.2--pyhdfd78af_0':
        'quay.io/biocontainers/panaroo:1.5.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_gene_presence_absence_roary.csv")            , emit: csv
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_gene_presence_absence.Rtab")                 , emit: rtab
    tuple val(meta), path("panaroo/${meta.species}_${meta.cluster_id}_summary_statistics.txt")                     , emit: summary
    path "versions.yml"                                                         , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    //Join the list of GFF files into a space-seperated string
    gff_files = gff.join(' ')
    """
    panaroo \\
        $args \\
        -t $task.cpus \\
        -o panaroo \\
        --clean-mode strict \\
        --remove-invalid-genes \\
        --threshold 0.98 \\
        --family_threshold 0.7 \\
        --core_threshold 0.99 \\
        -i $gff_files 

    # Rename with species prefix
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
