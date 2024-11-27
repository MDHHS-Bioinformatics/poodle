process REPORT_YAML {
    tag "$meta.species"
    label 'process_single'
    
    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(tree), //mashtree
    tuple val(meta), path(phylogeny),  //iqtree
    tuple val(meta), path(tsv), //snp-dists-core
    tuple val(meta), path(tree) //gubbins
    tuple val(meta), path(tsv), //snp-dists-gubbins
    tuple val(meta), path(csv), // panaroo
    tuple val(meta), path(rtab), // panaroo
    tuple val(meta), path(summary), // panaroo
    tuple val(meta), path(tsv) //gene-dists

    output:
    tuple val(meta) path(yaml), emit: meta_yaml

    script:
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"

    """
    python3 -c "
    import yaml
    import os
    from datetime import datetime, timezone

    # Generate a YAML file with parameters to render quarto
    data = {
            "species": $species,
            "cluster": $cluster_id,
            "snptree": $snptree,
            "snpdist": $snpdist,
            "mashtree": $mashtree,
            "gubbins": $gubbinstree,
            "gubsnpdist": $gubbinsdist,
            "panaroortab": $rtab,
            "panarooroary": $roary,
            "panaroodist": $panaroodist,
            "panaroosummary": $summary,
            }

    yaml_file_path = f"${species}_${cluster_id}_params.yaml")

    # Write the data to a YAML file
    with open(yaml_file_path, 'w') as yaml_file:
        yaml.dump(data, yaml_file, default_flow_style=False) "

    """
}

process REPORT_HTML {
    tag "$meta.species"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "quay.io/vascok/clusters@sha256:f0............."

    input:
    tuple val(meta) path(yaml)

    output:
    path '*.html' , emit: html

    script:
        script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"

    """

    quarto render cluster_report.qmd --execute-params $yaml --output ${prefix}.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quarto: \$(echo \$(quarto --version 2>&1)')
    END_VERSIONS

    """
}
