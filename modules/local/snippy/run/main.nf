process SNIPPY_RUN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/staphb/snippy:4.6.0-SC2'

    input:
    tuple val(meta), path(reads), path(assembly), path(annotation), path(reference)

    output:
    tuple val(meta), path("${meta.id}/${meta.id}.tab")              , emit: tab
    tuple val(meta), path("${meta.id}/${meta.id}.csv")              , emit: csv
    tuple val(meta), path("${meta.id}/${meta.id}.vcf")              , emit: vcf
    tuple val(meta), path("${meta.id}/${meta.id}.log")              , emit: log
    tuple val(meta), path("${meta.id}/${meta.id}.aligned.fa")       , emit: aligned_fa
    tuple val(meta), path("${meta.id}/${meta.id}.consensus.fa")     , emit: consensus_fa
    tuple val(meta), path("${meta.id}/${meta.id}.consensus.subs.fa"), emit: consensus_subs_fa
    tuple val(meta), path("${meta.id}/${meta.id}.txt")              , emit: txt
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    // Determine which input to use: prioritize reads, fallback to assembly if no reads
    def input_command
    if (meta.has_reads) {
        // If reads are available, use them
        if (meta.single_end) {
            input_command = "--se ${reads[0]}"  // Single-end reads
        } else {
            input_command = "--R1 ${reads[0]} --R2 ${reads[1]}"  // Paired-end reads
        }
    } else if (meta.has_assembly) {
        // If no reads, fallback to the assembly
        input_command = "--contigs ${assembly}"  // Assembly (contigs)
    } else {
        exit 1, "ERROR: Sample ${meta.id} does not have valid reads or assembly!"
    }

    """
    snippy \
        $args \
        --cpus $task.cpus \
        --ram $task.memory \
        --outdir $prefix \
        --reference $reference \
        --prefix $prefix \
        $input_command

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snippy: \$(echo \$(snippy --version 2>&1) | sed 's/snippy //')
    END_VERSIONS
    """
}
