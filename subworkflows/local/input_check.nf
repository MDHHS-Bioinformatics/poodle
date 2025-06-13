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
    //input_files.view()
    //branch out based on what kind of inputs we have
    input_files
        .branch{meta, fastqs, assembly, gff, ref->
            reads_only: meta.has_reads == true && meta.has_assembly == false
                return [ meta, fastqs, gff, ref ]
            assembly_only: meta.has_reads == false && meta.has_assembly == true
                return [ meta, assembly, gff, ref ]
            both: meta.has_reads == true && meta.has_assembly == true
                return [ meta, fastqs, assembly, gff, ref ]
        }
        .set{input_branched}
    //input_branched.reads_only.view()
    // We need to handle samples that used both reads and assemblies. We will priotize reads but need to keep
    // the assemblies for MASH downstream if want that to run later
    input_branched.both
        .multiMap { meta, fastqs, assembly, gff, ref ->
            reads_analysis: {
                def reads_meta = meta.clone()
                reads_meta.has_assembly = false
                return [reads_meta, fastqs, gff, ref]
            }()
            assembly_analysis: {
                def assembly_meta = meta.clone()
                assembly_meta.has_reads = false
                return [assembly_meta, assembly, gff, ref]
            }()
        }
        .set { both_split }
    //both_split.assembly_analysis.view()

    //Now create a channel to store all the files that will be used for analysis throughout the pipeline
    main_analysis = Channel.empty()
    main_analysis = main_analysis.mix(input_branched.reads_only)
    main_analysis = main_analysis.mix(input_branched.assembly_only)
    main_analysis = main_analysis.mix(both_split.reads_analysis)
    //main_analysis.view()
    //input_branched.assembly_only.view()
    //
    //Perform reference renaming if meta.has_assembly:true
    main_analysis
        .filter{meta, files, gff, reference -> meta.has_assembly == true}
        .map{meta, files, gff, reference -> tuple(meta, reference)}
        .set{ch_assemblies}
    //
    // //Store samples that don't have an assembly to recombined into the main channel later
    main_analysis
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
        .map{ meta, new_reference, empty_thing, files, gff, old_reference -> tuple(meta, files, gff, new_reference) }
        .set{renamed_input_files}


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
    final_input_files.view()
    //emit:
    // final_input_files                                 // channel: [ val(meta), [reads/assemblies], gff, reference]
    // //input_files                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions         // channel: [ versions.yml ]
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
