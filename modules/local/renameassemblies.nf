process RENAME_ASSEMBLIES {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(assemblies)

    output:
    tuple val(meta), path("renamed_assemblies/*"), emit: renamed_assemblies
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p renamed_assemblies
    python3 - <<'EOF'
import os
import shutil
from pathlib import Path

# Rename input files
assemblies = [${assemblies.collect { "'${it}'" }.join(", ")}]
prefix = "${prefix}"

for file in assemblies:
    file_path = Path(file)

    if file_path.name.endswith(('.fasta', '.fa', '.fna', '.fasta.gz', '.fa.gz', '.fna.gz')):
        # Rename assembly files
        extension = ''.join(file_path.suffixes)
        dest = Path('renamed_assemblies') / f"{prefix}{extension}"
        if file_path != dest:
            shutil.copy(file, dest)
    else:
        raise ValueError(f"Unrecognized file format for {file}")
EOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
