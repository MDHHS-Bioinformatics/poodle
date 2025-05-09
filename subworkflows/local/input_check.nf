//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK           } from '../../modules/local/samplesheet_check'
include { RENAME_REFERENCE            } from '../../modules/local/renamereference.nf'
include { RENAME_INPUTS               } from '../../modules/local/renameinputs.nf'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { input_files }
    //
    //Perform reference renaming if meta.has_assembly:true
    input_files
        .filter{meta, files, gff, reference -> meta.has_assembly == true}
        .map{meta, files, gff, reference -> tuple(meta, reference)}
        .set{ch_assemblies}
    //
    //Store samples that don't have an assembly to recombined into the main channel later
    input_files
        .filter{meta, files, gff, reference -> meta.has_assembly == false}
        .map{meta, files, gff, reference -> tuple(meta, files, gff, reference)}
        .set{ch_non_assemblies}
    //
    //Rename the reference files for samples that have assemblies
    RENAME_REFERENCE(ch_assemblies)
    //
    //Recreate the full channel with all the information we need
    ch_joined_assemblies = RENAME_REFERENCE.out.renamed_files.join(input_files)
    ch_joined_assemblies
        .map{ meta, new_reference, files, gff, old_reference -> tuple(meta, files, gff, new_reference) }
        .set{renamed_input_files}
    //
    //Mix the values of the non assemblies channel and the assemblies channel
    new_input_files = Channel.empty()
    new_input_files = new_input_files.mix(ch_non_assemblies)
    new_input_files = new_input_files.mix(renamed_input_files)


    final_input_files = Channel.empty()
    if (params.rename_files){
        //rename the final files
        RENAME_INPUTS(new_input_files)
        //fix the assembly channel
        RENAME_INPUTS.out.renamed_files
        .branch {meta, files, gff, reference ->
            assembly: meta.has_assembly == true && meta.has_reads == false
                return tuple(meta, [files], gff, reference)
            fastqs: meta.has_reads == true
                return tuple(meta, files, gff, reference)
        }
        .set{branch_results}
        final_input_files = final_input_files.mix(branch_results)
    }
    else {
        final_input_files = final_input_files.mix(new_input_files)

    }
    //final_input_files.view()
    emit:
    final_input_files                                 // channel: [ val(meta), [reads/assemblies], gff, reference]
    //input_files                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions         // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] or [ assembly ] ]
def create_fastq_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id          = row.sample
    meta.single_end  = row.single_end ? row.single_end.toBoolean() : false
    meta.has_reads   = row.fastq_1 && row.fastq_1 != ""  // Check if reads are available
    meta.has_assembly = row.assembly && row.assembly != ""  // Check if an assembly is available
    meta.cluster_id = row.cluster_id
    meta.species = row.species

    // Validate and add file paths
    def input_meta = []
        if (meta.has_reads) {
            // Validate reads
            if (!file(row.fastq_1).exists()) {
                        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
                    }
            if (meta.single_end) {
                // Single-end reads
                input_meta = [ meta, [ file(row.fastq_1) ], file(row.gff), file(row.reference) ]
            } else {
                if (!file(row.fastq_2).exists()) {
                    exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
                }
                // Paired-end reads
                input_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ], file(row.gff), file(row.reference) ]
            }
        } else if (meta.has_assembly){
        //If assemblies are avaiable, check and add them to the meta map
        if (!file(row.assembly).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Assembly file does not exist!\n${row.assembly}"
        }
        // Add the assembly path to the meta map
        input_meta = [ meta, [ file(row.assembly) ], file(row.gff), file(row.reference)  ]
    } else {
        // No valid reads or assembly
        exit 1, "ERROR: Sample ${row.sample} does not have valid reads or assembly!"
    }

    return input_meta
}
