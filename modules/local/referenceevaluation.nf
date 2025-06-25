process REFERENCE_EVALUATION {
    tag "$meta.species"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"
        
    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path("reference_evaluation.tsv"), emit: tsv
    
    script:
    prefix = task.ext.prefix ?: "${meta.species}_${meta.cluster_id}"
    cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
    species = task.ext.prefix ?: "${meta.species}"
    """
    python3 -c "
import sys

# Print header
print('sample\\tgenome_fraction\\talignment_quality')

# Read and process the input file
with open('$txt') as f:
    next(f)  # Skip the header line
    for line in f:
        fields = line.strip().split('\\t')
        sample = fields[0]
        length = float(fields[1])
        aligned = float(fields[2])
        genome_fraction = (aligned / length) * 100

        # Determine alignment quality
        if genome_fraction >= 98:
            alignment_quality = 'Excellent'
        elif genome_fraction >= 95:
            alignment_quality = 'Very Good'
        elif genome_fraction >= 85:
            alignment_quality = 'Good'
        elif genome_fraction >= 75:
            alignment_quality = 'Fair'
        else:
            alignment_quality = 'Poor'

        # Print the result for each sample
        print(f'{sample}\\t{genome_fraction:.2f}\\t{alignment_quality}')
    " > reference_evaluation.tsv
    """
}
