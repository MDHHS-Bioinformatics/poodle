//
// Check input samplesheet and get read channels
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK as SAMPLESHEET_CHECK_FILES         } from '../../modules/local/samplesheet_check'
include { RENAME_REFERENCE                                     } from '../../modules/local/rename_reference.nf'
include { RENAME_ANNOTATION                                    } from '../../modules/local/rename_annotation.nf'
include { RENAME_ASSEMBLY                                      } from '../../modules/local/rename_assembly.nf'

/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/

def create_sample_input(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.has_reads    = !!(row.fastq_1 && row.fastq_1.trim())
    meta.has_assembly = !!(row.assembly && row.assembly.trim())
    meta.single_end   = meta.has_reads && !(row.fastq_2 && row.fastq_2.trim())
    meta.cluster_id   = row.cluster_id
    meta.species      = row.species

    def reads = []
    def assembly = null

    if (meta.has_reads) {
        def read1 = file(row.fastq_1)
        if (!read1.exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
        }

        if (meta.single_end) {
            reads = [read1]
        } else {
            def read2 = file(row.fastq_2)
            if (!read2.exists()) {
                exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
            }
            reads = [read1, read2]
        }
    }

    if (meta.has_assembly) {
        assembly = file(row.assembly)
        if (!assembly.exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Assembly file does not exist!\n${row.assembly}"
        }
    }

    if (!meta.has_reads && !meta.has_assembly) {
        exit 1, "ERROR: Sample ${row.sample} does not have valid reads or assembly!"
    }

    def annotation = file(row.annotation)
    if (!annotation.exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Annotation file does not exist!\n${row.annotation}"
    }

    def reference = file(row.reference)
    if (!reference.exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Reference file does not exist!\n${row.reference}"
    }

    return [meta, reads, assembly, annotation, reference]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow INPUT_CHECK {

    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK_FILES ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_sample_input(it) }
        .set { input_files }
    //
    // MODULE: Rename the reference file for all samples
    //
    RENAME_REFERENCE(
        input_files.map{
            meta, reads, assembly, annotation, reference -> tuple(meta,reference)
        }
    )
    //
    // Recreate the full channel with renamed reference
    //
    ch_renamed_refs = RENAME_REFERENCE.out.renamed_reference.join(input_files)
    ch_renamed_refs
        .map{meta, renamed_reference, reads, assembly, annotation, reference -> tuple(meta, reads, assembly, annotation, renamed_reference)}
        .set{new_input_files}
    //
    // MODULE: Rename assemblies and annotations if desired
    //
    final_input_files = Channel.empty()
    if (params.rename_files){
        //Rename the annotation files
        RENAME_ANNOTATION(new_input_files)

        //Branch out if we need to rename assembly or not
        RENAME_ANNOTATION.out.renamed_files
            .branch{ meta, reads, assembly, annotation, reference ->
            has_assembly: meta.has_assembly == true
                return [ meta, reads, assembly, annotation, reference ]
            no_assembly: meta.has_assembly == false
                return [meta, reads, assembly, annotation, reference ]
            }
            .set{initial_renaming}

        //Rename the assembly files for channels with assembly
        RENAME_ASSEMBLY(initial_renaming.has_assembly)

        //Recombine everything again
        final_input_files = final_input_files.mix(RENAME_ASSEMBLY.out.renamed_files)
        final_input_files = final_input_files.mix(initial_renaming.no_assembly)

    }
    else {
        final_input_files = final_input_files.mix(new_input_files)

    }
    
    emit:
    final_input_files                                 // channel: [ val(meta), [reads], assembly, annotation, reference ]
    versions = SAMPLESHEET_CHECK_FILES.out.versions   // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
