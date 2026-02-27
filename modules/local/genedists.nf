process GENEDISTS {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_low'
    
    container "quay.io/mdhhs_bioinformatics/quarto-wgs-reporting:1.0.0"

    input:
    tuple val(meta), path(rtab)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in MDHHS-Bioinformatics/poodle/bin/
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    # Calculate gene presence-absence Hamming distances
    gene_dists.R ${rtab} ${prefix}_gene_presence_absence_dist.tsv

    # Capture the R version for versions.yml
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | sed -n 's/^R version \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS
    """
}
