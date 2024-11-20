process RENAME_INPUTS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(input_files), path(gff), path(reference)

    output:
    tuple val(meta), path("renamed_files/*"), path(gff), path(reference), emit: renamed_files

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p renamed_files

    for file in ${input_files}; do
        # Check for FASTQ files and skip renaming
        if [[ "\$file" == *".fastq.gz" || "\$file" == *.fastq || "\$file" == *.fq.gz || "\$file" == *.fq ]]; then
            # Skip renaming of FASTQ files
            cp "\$file" "renamed_files/\$(basename \$file)"
        elif [[ "\$file" == *.fasta || "\$file" == *.fa || "\$file" == *.fna || "\$file" == *.fasta.gz || "\$file" == *.fa.gz || "\$file" == *.fna.gz ]]; then
            # Rename assembly files
            extension="\${file##*.}"
            newname="renamed_files/${prefix}.\$extension"
            cp "\$file" "\$newname"
        elif [[ "\$file" == *.gff || "\$file" == *.gff3 ]]; then
            # Rename GFF files
            extension="\${file##*.}"
            newname="renamed_files/${prefix}.\$extension"
            cp "\$file" "\$newname"
        else
            echo "Unrecognized file format for \$file" >&2
            exit 1
        fi
    done

    if [[ -n "${gff}" ]]; then
        if [[ "${gff}" == *.gff || "${gff}" == *.gff3 ]]; then
            gff_extension="\${gff##*.}"
            cp "${gff}" "renamed_files/${prefix}.\${gff_extension}"
        else
            echo "Unrecognized GFF file format for ${gff}" >&2
            exit 1
        fi
    fi

    """
}
