process RENAME_INPUTS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(input_files), path(gff), path(reference)

    output:
    tuple val(meta), path("renamed_files/*"), path("renamed_gff/*"), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p renamed_files
    mkdir -p renamed_gff
    python3 - <<'EOF'
import os
import shutil
from pathlib import Path

# Rename input files
input_files = [${input_files.collect { "'${it}'" }.join(", ")}]
prefix = "${prefix}"

for file in input_files:
    file_path = Path(file)

    if file_path.name.endswith(('.fastq.gz', '.fastq', '.fq.gz', '.fq')):
        # Keep FASTQ files as is
        dest = Path('renamed_files') / file_path.name
        if file_path != dest:
            shutil.copy(file, dest)
    elif file_path.name.endswith(('.fasta', '.fa', '.fna', '.fasta.gz', '.fa.gz', '.fna.gz')):
        # Rename assembly files
        extension = ''.join(file_path.suffixes)
        dest = Path('renamed_files') / f"{prefix}{extension}"
        if file_path != dest:
            shutil.copy(file, dest)
    else:
        raise ValueError(f"Unrecognized file format for {file}")

# Rename GFF file if provided
gff = "${gff}" if "${gff}" != 'null' else None
if gff:
    gff_path = Path(gff)
    if gff_path.name.endswith(('.gff', '.gff3')):
        gff_extension = ''.join(gff_path.suffixes)
        renamed_gff = Path("renamed_gff") / f"{prefix}{gff_extension}"
        if gff_path != renamed_gff:
            shutil.copy(gff, renamed_gff)
    else:
        raise ValueError(f"Unrecognized GFF file format for {gff}")
EOF
    """
}
