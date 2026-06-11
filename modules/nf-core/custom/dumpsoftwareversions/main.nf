process CUSTOM_DUMPSOFTWAREVERSIONS {
    label 'process_single'

    // Requires `pyyaml` which does not have a dedicated container but is in the MultiQC container
    conda "bioconda::multiqc=1.35"
    container 'quay.io/biocontainers/multiqc@sha256:0fae3fc02ac26ac0ca18475bd363504d2d39db4ff4391c5899648b8490abceee'
    // 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_0'

    input:
    path versions

    output:
    path "software_versions.yml"    , emit: yml
    path "software_versions_mqc.yml", emit: mqc_yml
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'dumpsoftwareversions.py'
}
