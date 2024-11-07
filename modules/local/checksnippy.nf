process CHECKSNIPPY {
    input:
    tuple val(meta), path(input_files), path(gff), path(reference)

    output:
    tuple val(meta), path(input_files), path(gff), path(reference), val(run_snippy), emit: snippy_check

    script:
    """
    # Extract the header information from the VCF file (line 6)
    vcf_file_path="${params.outdir}/${meta.species}/${meta.cluster_id}/snippy_run/${meta.id}/${meta.id}.vcf"
    reference_header=$(sed -n '6p' $vcf_file_path | grep -oP 'ID=\\K[^,]+')

    # Check if the reference header exists in the reference FASTA file
    if grep -q "$reference_header" $reference; then
        same_reference=true
    else
        same_reference=false
    fi

    # Check if SNIPPY_RUN is needed based on reference and directory status
    snippy_dir="${params.outdir}/${meta.species}/${meta.cluster_id}/snippy_run/${meta.id}"
    if [ -d "$snippy_dir" ]; then
        if [ "$same_reference" = true ]; then
            run_snippy=false
        else
            run_snippy=true
        fi
    else
        run_snippy=true
    fi

    # Output result to pass along the channel
    echo "$meta"
    echo "$input_files"
    echo "$gff"
    echo "$reference"
    echo "$run_snippy"
    """
}
