//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK as SAMPLESHEET_CHECK_FILES         } from '../../modules/local/samplesheet_check'
include { SAMPLESHEET_CHECK as SAMPLESHEET_CHECK_ASSEMBLIES           } from '../../modules/local/samplesheet_check'
include { RENAME_REFERENCE            } from '../../modules/local/renamereference.nf'
include { RENAME_GFF                  } from '../../modules/local/rename_gff.nf'
include { RENAME_ASSEMBLY             } from '../../modules/local/rename_assembly.nf'
workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK_FILES ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { input_files }

    //
    //Rename the reference file for all samples
    //
    RENAME_REFERENCE(
        input_files.map{
            meta, reads, assemblies, gff, reference -> tuple(meta,reference)
        }
    )

    //Recreate the full channel with all the information we need
    ch_renamed_refs = RENAME_REFERENCE.out.renamed_files.join(input_files)
    ch_renamed_refs
        .map{meta, new_reference, reads, assemblies, gff, old_reference -> tuple(meta, reads, assemblies, gff, new_reference)}
        .set{new_input_files}
    //new_input_files.view()

    //Rename the files if desired
    final_input_files = Channel.empty()
    if (params.rename_files){
        //Rename the GFF files
        RENAME_GFF(new_input_files)

        //Branch out if we need to rename assemblies or not
        RENAME_GFF.out.renamed_files
            .branch{ meta, reads, assemblies, gff, reference ->
            has_assembly: meta.has_assembly == true
                return [ meta, reads, assemblies, gff, reference ]
            no_assembly: meta.has_assembly == false
                return [meta, reads, assemblies, gff, reference ]
            }
            .set{initial_renaming}

        //Rename the assembly files for channels with assemblies
        RENAME_ASSEMBLY(initial_renaming.has_assembly)

        //Recombine everything again
        final_input_files = final_input_files.mix(RENAME_ASSEMBLY.out.renamed_files)
        final_input_files = final_input_files.mix(initial_renaming.no_assembly)

    }
    else {
        final_input_files = final_input_files.mix(new_input_files)

    }

    emit:
    final_input_files                                 // channel: [ val(meta), [reads/assemblies], gff, reference ]
    versions = SAMPLESHEET_CHECK_FILES.out.versions         // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] or [ assembly ], [ assembly ] or [], gff, reference ]
def create_fastq_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id          = row.sample
    meta.single_end  = row.single_end ? row.single_end.toBoolean() : false
    meta.has_reads   = row.fastq_1 && row.fastq_1 != ""  // Check if reads are available
    meta.has_assembly = row.assembly && row.assembly != ""  // Check if an assembly is available
    meta.cluster_id = row.cluster_id
    meta.species = row.species

    // Initialize arrays for reads and assembly
    def reads_files = []
    def assembly_files = []

    // Handle reads if available
    if (meta.has_reads) {
        // Validate reads
        if (!file(row.fastq_1).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
        }
        if (meta.single_end) {
            // Single-end reads
            reads_files = [ file(row.fastq_1) ]
        } else {
            if (!file(row.fastq_2).exists()) {
                exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
            }
            // Paired-end reads
            reads_files = [ file(row.fastq_1), file(row.fastq_2) ]
        }
    }

    // Handle assembly if available
    if (meta.has_assembly) {
        // Validate assembly
        if (!file(row.assembly).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Assembly file does not exist!\n${row.assembly}"
        }
        assembly_files = [file(row.assembly)]
    }

    // Validate that at least one input type is available
    if (!meta.has_reads && !meta.has_assembly) {
        exit 1, "ERROR: Sample ${row.sample} does not have valid reads or assembly!"
    }

    // Return structure: [ meta, reads_files, assembly_files, gff, reference ]
    def input_meta = [ meta, reads_files, assembly_files, file(row.gff), file(row.reference) ]

    return input_meta
}

def create_assembly_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.single_end?.toBoolean() ?: false
    meta.has_reads    = row.fastq_1 && row.fastq_1.trim()
    meta.has_assembly = row.assembly && row.assembly.trim()
    meta.cluster_id   = row.cluster_id
    meta.species      = row.species

    // Return null if no assembly – this will be filtered out in a map/filter
    if (!meta.has_assembly) {
        return null
    }

    // Validate file exists
    def assembly_file = file(row.assembly)
    if (!assembly_file.exists()) {
        exit 1, "ERROR: Assembly file does not exist for sample '${row.sample}': ${row.assembly}"
    }

    return [meta, assembly_file]
}
