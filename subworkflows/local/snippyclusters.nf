//
// Perform Snippy analysis by species per clsuter
//

//Modules
//include { SNIPPY_CORE                   } from '../../modules/nf-core/snippy/core/main'
include { SNIPPY_RUN                    } from '../../modules/nf-core/snippy/run/main'



/*
=============================================================================================================================
    SUBWORKFLOW FUNCTIONS
=============================================================================================================================
*/

//Function for determinging if prior snippy results exists for a sample/species/cluster combination
def verify_previous_snippy_run (species, cluster_id, sample_id) {
    //create the path to what would be the Snippy vcf
    snippy_vcf_path = file(params.outdir).resolve(species).resolve(cluster_id).resolve('snippy_run').resolve(sample_id).resolve("${sample_id}.vcf")
    //Check if the snippy_path exists
    vcf_path_exists = snippy_vcf_path.exists() ? true : false
    //println " ${snippy_vcf_path} exists? ${vcf_path_exists}" // This prints the path for debugging
    return vcf_path_exists
}

//Function to read in vcf path and check the reference
def read_vcf_for_ref(species, cluster_id, sample_id, ref) {
    // Create the path to Snippy vcf
    def snippy_vcf_path = file("${params.outdir}/${species}/${cluster_id}/snippy_run/${sample_id}/${sample_id}.vcf")

    if (snippy_vcf_path.exists()) {
    // Extract the header information from the VCF file (line 6)
    reference_in_vcf = snippy_vcf_path.withReader { reader ->
        def line
        5.times { reader.readLine() } // Skip the first 5 lines
        line = reader.readLine() // Read the 6th line
        def rawReference = line.find(/ID=([^,]+)/) { match, id -> id } // Extract the ID value
        if (rawReference) {
            // Split at '_', take the first part, and append '.fna'
            rawReference.split('_')[0] + '.fna'
        }
    }
    }
    // Extract just the filename from the full path of ref
    def ref_filename = file(ref).name

    // Compare the reference in VCF with the provided reference filename
    def reference_match = (reference_in_vcf == ref_filename)

    return [reference_match, snippy_vcf_path] //[reference_in_vcf, reference_match, ref_filename]
}

workflow SNIPPY_CLUSTERS {

    take:
    // TODO nf-core: edit input (take) channels
    ch_input_files // channel: [ val(meta), [ files ], gff, ref ]

    main:

    ch_versions = Channel.empty()

    ch_input_files
    .map{ meta, files, gff, ref ->
            tuple(meta, files, gff, ref, verify_previous_snippy_run(meta.species, meta.cluster_id, meta.id))}
    .branch {
        run_snippy: it[4] == false
        verify_vcf: it[4] == true
    }
    .set{input_files_status}

    //check the vcf file
    input_files_status.verify_vcf
    .map { meta, files, gff, ref, status ->
            tuple( meta, files, gff, ref, read_vcf_for_ref(meta.species, meta.cluster_id, meta.id, ref))}
    .branch {
        vcf_match : it[4][0] == true
        rerun_snippy: it[4][0] == false
    }
    .set{previous_vcf}

    //
    // Module: Run Snippy on the files
    //

    //First create an empty channel to store the samples that need snippy run on them
    ch_snippy_to_run = Channel.empty()
    //Add the files that have never had snippy run on them
    ch_snippy_to_run = ch_snippy_to_run.mix( input_files_status.run_snippy
        .map{ meta, files, gff, ref, status -> tuple(meta, files, gff, ref)})
    //Add the files that need to have snippy rerun on them
    ch_snippy_to_run = ch_snippy_to_run.mix( previous_vcf.rerun_snippy
        .map{meta, files, gff, ref, vcf_info -> tuple(meta, files, gff, ref)})

    SNIPPY_RUN(
        ch_snippy_to_run
    )

    //Initialize channel to store VCF results
    ch_snippy_vcfs = Channel.empty()
    //Add the results from previous samples that already have a vcf
    ch_snippy_vcfs = ch_snippy_vcfs.mix(
        previous_vcf.vcf_match
        .map{meta, files, gff, ref, vcf_info -> tuple(meta, vcf_info[1])}
    )
    //Add the results from the Snippy run
    ch_snippy_vcfs = ch_snippy_vcfs.mix(SNIPPY_RUN.out.vcf)
    ch_snippy_vcfs.view()

    //Group VCFs by species and by cluster
    // ch_snippy_vcfs
    // .map { meta, vcf -> tuple([[species:meta.species, cluster_id:meta.cluster_id], vcf]) }
    // .groupTuple(by: [0])
    // .set { ch_collected_vcfs }
    // ch_collected_vcfs.view()
    //Group the aligned_fa's by species and by cluster
    // SNIPPY_RUN.out.aligned_fa
    // .map {meta, aligned_fa -> tuple([[species:meta.species, cluster_id:meta.cluster_id], aligned_fa])}
    // .groupTuple(by:[0])
    // .set{ch_collected_aligned_fa}
    // //Join the VCF and aligned_fa channels for snippy core
    // ch_collected_vcfs.join(ch_collected_aligned_fa).set{ch_vcf_and_aligned_fa}
    // //ch_snippy_core_input.view()
    // //Get the unique reference per species per cluster
    // INPUT_CHECK.out.final_input_files
    // .map { meta, input_files, gff, reference -> tuple([[species: meta.species, cluster_id: meta.cluster_id], reference]) }
    // .distinct { it[1] }  // Use distinct to keep only unique reference values
    // .set{ch_ref_per_species_per_cluster}
    // //Join the reference with the vcf and aligned fa
    // ch_vcf_and_aligned_fa.join(ch_ref_per_species_per_cluster).set{ch_snippy_core_input}
    //ch_snippy_core_input.view()


    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

