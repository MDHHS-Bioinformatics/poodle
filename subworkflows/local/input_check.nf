//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { input_files }
    // Extract unique species values
    unique_species = input_files
        .map { row -> row[5] } // species is the 6th element in input_files, as in [ meta, [ files ], gff, reference, cluster_id, species ]
        .unique() // Get only unique species values
        .set { species_channel }

    emit:
    input_files                                     // channel: [ val(meta), [ reads ] ]
    species_channel                             // channel of unique species values
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] or [ assembly ] ]
def create_fastq_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id          = row.sample
    meta.single_end  = row.single_end ? row.single_end.toBoolean() : false
    meta.has_reads   = row.fastq_1 && row.fastq_1 != ""  // Check if reads are available
    meta.has_assembly = row.assembly && row.assembly != ""  // Check if an assembly is available
    // meta.cluster_id = row.cluster_id
    // meta.species = row.species

    // Validate and add file paths
    def input_meta = []

    if (meta.has_reads) {
        // If reads are available, check and add them to the meta map
        if (!file(row.fastq_1).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
        }
        if (meta.single_end) {
            // Single-end case
            input_meta = [ meta, [ file(row.fastq_1) ], file(row.gff),file(row.reference),row.cluster_id, row.species  ]
        } else {
            if (!file(row.fastq_2).exists()) {
                exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
            }
            // Paired-end case
            input_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ], file(row.gff),file(row.reference),row.cluster_id, row.species ]
        }
    } else if (meta.has_assembly) {
        // If no reads but assembly is available, use the assembly
        if (!file(row.assembly).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Assembly file does not exist!\n${row.assembly}"
        }
        // Add the assembly path to the meta map
        input_meta = [ meta, [ file(row.assembly) ], file(row.gff),file(row.reference),row.cluster_id, row.species  ]
        //meta.assembly = row.assembly
    } else {
        exit 1, "ERROR: Sample ${row.sample} does not have valid reads or assembly!"
    }

    return input_meta
}
