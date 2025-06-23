//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK as SAMPLESHEET_CHECK_FILES         } from '../../modules/local/samplesheet_check'
include { SAMPLESHEET_CHECK as SAMPLESHEET_CHECK_ASSEMBLIES           } from '../../modules/local/samplesheet_check'
include { RENAME_REFERENCE            } from '../../modules/local/renamereference.nf'
include { RENAME_INPUTS            } from '../../modules/local/renameinputs.nf'
include { RENAME_ASSEMBLIES               } from '../../modules/local/renameassemblies.nf'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK_FILES ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { input_files }
  
    SAMPLESHEET_CHECK_ASSEMBLIES ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_assembly_channel(it) }
        .set { assembly_files }

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

    final_assembly_files = Channel.empty()
    if (params.rename_files){
        //rename the final files
        RENAME_ASSEMBLIES(assembly_files)
        final_assembly_files = RENAME_ASSEMBLIES.out.renamed_assemblies
    }
    else {
        final_assembly_files = final_assembly_files.mix(assembly_files)
    }
    //final_assembly_files.view()

    //final_input_files.view()
    emit:
    final_input_files                                 // channel: [ val(meta), [reads/assemblies], gff, reference ]
    final_assembly_files                              // channel: [ val(meta), assembly ]
    versions = SAMPLESHEET_CHECK_FILES.out.versions         // channel: [ versions.yml ]
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
