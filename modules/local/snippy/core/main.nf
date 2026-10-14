process SNIPPY_CORE {
    tag "${meta.species}_${meta.cluster_id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/staphb/snippy@sha256:011bb8ece52183719d2a188ff18f056a2e43367abf32a99f334da10736e0b79c'
    // 'quay.io/staphb/snippy:4.6.0-SC2'

    input:
    tuple val(meta), path(vcf), path(aligned_fa), path(reference)

    output:
    tuple val(meta), path("${prefix}.aln"),             emit: aln, optional: true
    tuple val(meta), path("${prefix}.full.aln"),        emit: full_aln
    tuple val(meta), path("${prefix}_clean.full.aln"),  emit: clean_full_aln
    tuple val(meta), path("${prefix}.tab"),             emit: tab, optional: true
    tuple val(meta), path("${prefix}.vcf"),             emit: vcf, optional: true
    tuple val(meta), path("${prefix}.txt"),             emit: txt
    tuple val(meta), path("${prefix}.status.tsv"),      emit: status
    path "versions.yml",                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    def is_compressed = reference.getName().endsWith(".gz") ? true : false
    def reference_name = reference.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $reference > $reference_name
    fi

    # Collect samples into necessary folders
    mkdir samples
    find . -name "*.vcf" | sed 's/\\.vcf\$//' | xargs -I {} bash -c 'mkdir samples/{}'
    find . -name "*.vcf" | sed 's/\\.vcf\$//' | xargs -I {} bash -c 'cp -L {}.vcf samples/{}/{}.vcf'
    find . -name "*.aligned.fa" | sed 's/\\.aligned.fa\$//' | xargs -I {} bash -c 'cp -L {}.aligned.fa samples/{}/{}.aligned.fa'

    # Run snippy-core and capture errors
    set +e

    snippy-core \
        $args \
        --ref $reference_name \
        --prefix $prefix \
        samples/* \
        2> snippy_core.log

    exit_code=\$?

    set -e

    if [ "\$exit_code" -eq 0 ]; then

        status="SUCCESS"

    else

        # Recover only from the known zero-SNP condition
        if grep -q "No SNPs were detected" snippy_core.log \
        && grep -q "Could not run: snp-sites" snippy_core.log \
        && [ -s "${prefix}.full.aln" ] \
        && [ -s "${prefix}.txt" ]; then

            status="ZERO_CORE_SNPS"

            echo "WARNING: No qualifying core SNPs for ${prefix}"

        else
            cat snippy_core.log >&2
            exit "\$exit_code"
        fi
    fi

    # Clean full alignment
    snippy-clean_full_aln \
        ${prefix}.full.aln \
        > ${prefix}_clean.full.aln

    # Write status for downstream routing
    printf "cluster_id\tstatus\n%s\t%s\n" \
        "${meta.cluster_id}" \
        "\$status" > ${prefix}.status.tsv

    # Write versions.yml
    printf '"%s":\n  snippy-core: "%s"\n' \
        "${task.process}" \
        "\$(snippy-core --version 2>&1 | sed 's/snippy-core //')" \
        > versions.yml
    """
}
