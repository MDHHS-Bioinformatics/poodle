//
// Perform Snippy analysis by species per clsuter
//

//Modules
include { SNIPPY_CORE                   } from '../../modules/nf-core/snippy/core/main'
include { SNIPPY_RUN                    } from '../../modules/nf-core/snippy/run/main'
include { REFERENCE_EVALUATION          } from '../../modules/local/referenceevaluation.nf'


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
    }
    }

    // Read the first line of the reference filename
    def ref_name = file(ref).withReader { reader ->
        def line
        line = reader.readLine()
    }

    // Compare the reference in VCF with the provided reference filename
    def reference_match = (ref_name.contains(reference_in_vcf))

    return [reference_match, snippy_vcf_path] //[reference_in_vcf, reference_match, ref_filename]
}

//Function to read in aligned.fa from a previously run sample
def read_aligned_fa(species,cluster_id,sample_id) {
    //Create the path to the Snippy aligned.fa
    def snippy_aligned_fa_path = file("${params.outdir}/${species}/${cluster_id}/snippy_run/${sample_id}/${sample_id}.aligned.fa")

    return snippy_aligned_fa_path
}

workflow SNIPPY_CLUSTERS {

    take:
    ch_input_files // channel: [ val(meta), [ files ], gff, ref ]

    main:

    ch_versions = Channel.empty()

    ch_input_files
    .map{ meta, reads, assembly , gff, ref ->
            tuple(meta, reads, assembly, gff, ref, verify_previous_snippy_run(meta.species, meta.cluster_id, meta.id))}
    .branch {
        run_snippy: it[5] == false
        verify_vcf: it[5] == true
    }
    .set{input_files_status}

    //check the vcf file
    input_files_status.verify_vcf
    .map { meta, reads, assembly, gff, ref, status ->
            tuple( meta, reads, assembly, gff, ref, read_vcf_for_ref(meta.species, meta.cluster_id, meta.id, ref))}
    .branch {
        vcf_match : it[5][0] == true
        rerun_snippy: it[5][0] == false
    }
    .set{previous_vcf}


    //
    // Module: Run Snippy on the files
    //

    //First create an empty channel to store the samples that need snippy run on them
    ch_snippy_to_run = Channel.empty()
    //Add the files that have never had snippy run on them
    ch_snippy_to_run = ch_snippy_to_run.mix( input_files_status.run_snippy
        .map{ meta, reads, assembly, gff, ref, status -> tuple(meta, reads, assembly, gff, ref)})
    //Add the files that need to have snippy rerun on them
    ch_snippy_to_run = ch_snippy_to_run.mix( previous_vcf.rerun_snippy
        .map{meta, reads, assembly, gff, ref, vcf_info -> tuple(meta, reads, assembly, gff, ref)})

    //
    // MODULE: Snippy run
    //
    SNIPPY_RUN(
        ch_snippy_to_run
    )
    ch_versions = ch_versions.mix(SNIPPY_RUN.out.versions.first())

    //Initialize channel to store VCF results
    ch_snippy_vcfs = Channel.empty()

    //Add the results from previous samples that already have a vcf
    ch_snippy_vcfs = ch_snippy_vcfs.mix(
        previous_vcf.vcf_match
        .map{meta, reads, assembly, gff, ref, vcf_info -> tuple(meta, vcf_info[1])}
    )
    //Add the results from the Snippy run
    ch_snippy_vcfs = ch_snippy_vcfs.mix(SNIPPY_RUN.out.vcf)

    //Group VCFs by species and by cluster
    ch_snippy_vcfs
        .map { meta, vcf -> tuple([[species:meta.species, cluster_id:meta.cluster_id], vcf]) }
        .groupTuple(by: [0])
        .set { ch_collected_vcfs }

    //Initialize empty channel to story aligned fa results
    ch_snippy_aligned_fas = Channel.empty()

    //Get the algined.fa from previously ran Samples
    previous_vcf.vcf_match
        .map{meta, reads, assembly, gff, ref, vcf_info ->
        tuple(meta, read_aligned_fa(meta.species, meta.cluster_id, meta.id))}
        .set{previous_aliged_fa}
    //Add previous aligned fasta to channel
    ch_snippy_aligned_fas = ch_snippy_aligned_fas.mix(previous_aliged_fa)
    //Add new snippy results
    ch_snippy_aligned_fas = ch_snippy_aligned_fas.mix(SNIPPY_RUN.out.aligned_fa)
    //Group Aligned fasta by species and by cluster
    ch_snippy_aligned_fas
        .map { meta, aligned_fa -> tuple([[species:meta.species, cluster_id:meta.cluster_id], aligned_fa])}
        .groupTuple(by: [0])
        .set {ch_collected_aligned_fa}
    //Get the unique reference per species per cluster
    ch_input_files
    .map{ meta, reads, assembly, gff, reference -> tuple([[species:meta.species, cluster_id:meta.cluster_id], reference])}
    .distinct{ file(it[1]).name } // Use distinct to keep only unique reference values
    .set{ ch_ref_per_species_per_cluster }

    //Join the vcfs with aligned fa channel
    ch_collected_vcfs.join(ch_collected_aligned_fa)
        .set{ch_vcf_and_aligned_fa}
    //join the vcfs/aligned fa with the reference channel
    ch_vcf_and_aligned_fa.join(ch_ref_per_species_per_cluster)
        .set{ch_snippy_core_input}

    //
    // MODULE: Identify core SNPS
    //
    SNIPPY_CORE(
        ch_snippy_core_input
    )
    ch_versions = ch_versions.mix(SNIPPY_CORE.out.versions.first())

    //
    //MODULE: Evaluate reference
    //
    REFERENCE_EVALUATION(
        SNIPPY_CORE.out.txt
    )

    emit:
    versions        = ch_versions                     // channel: [ versions.yml ]
    aln             = SNIPPY_CORE.out.aln             // channel: [ val(meta), aln]
    clean_full_aln  = SNIPPY_CORE.out.clean_full_aln  // channel: [ val(meta), clean_full_aln]
    snippy_txt      = SNIPPY_RUN.out.txt              // channel: [ val(meta), txt]
    ref_evaluation  = REFERENCE_EVALUATION.out.tsv    // channel: [ val(meta), tsv]

}

