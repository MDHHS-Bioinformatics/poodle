/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowProcessclusterperspecies.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CLEAN_TREE                  } from '../modules/local/cleantree'
include { GENEDISTS                   } from '../modules/local/genedists'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { SNIPPY_CLUSTERS             } from '../subworkflows/local/snippyclusters.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                      } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { SNPDISTS as SNPDISTS_SNIPPY  } from '../modules/nf-core/snpdists/main'
include { SNPDISTS as SNPDISTS_GUBBINS } from '../modules/nf-core/snpdists/main'
include { IQTREE                       } from '../modules/nf-core/iqtree/main'
include { GUBBINS                      } from '../modules/nf-core/gubbins/main'
include { PANAROO_RUN                  } from '../modules/nf-core/panaroo/run/main'
include { MASHTREE                     } from '../modules/nf-core/mashtree/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow PROCESSCLUSTERPERSPECIES {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    //
    // SUBWORKFLOW: Snippy run and Snippy core (verifying prior results and reference)
    //
    SNIPPY_CLUSTERS(
        INPUT_CHECK.out.final_input_files
    )
    ch_versions = SNIPPY_CLUSTERS.out.versions

    //
    // MODULE: Core SNP Distances
    //
    SNPDISTS_SNIPPY(
        SNIPPY_CLUSTERS.out.aln
    )
    ch_versions = ch_versions.mix(SNPDISTS_SNIPPY.out.versions.first())

    //
    // MODULE: Create core-SNP phylogeny
    //
    IQTREE(SNIPPY_CLUSTERS.out.aln)
    ch_versions = ch_versions.mix(IQTREE.out.versions)

    //
    // MODULE: Remove reference and root at midpoint
    //
    CLEAN_TREE(IQTREE.out.phylogeny)
    ch_versions = ch_versions.mix(CLEAN_TREE.out.versions)

    //
    // MODULE: Gubbins
    //
    if (params.gubbins) {
        GUBBINS(SNIPPY_CLUSTERS.out.clean_full_aln)
        ch_versions = ch_versions.mix(GUBBINS.out.versions)

        SNPDISTS_GUBBINS(GUBBINS.out.fasta)
        ch_versions = ch_versions.mix(SNPDISTS_GUBBINS.out.versions)
    }

    //
    // MODULE: Gene-prescene abscence with Panaroo
    //
    //Collect GFF files by species and cluster
    INPUT_CHECK.out.final_input_files
    .map{meta, input_files, gff, reference -> tuple([[species:meta.species,cluster_id:meta.cluster_id],gff])}
    .groupTuple(by:[0])
    .set{ch_collected_gffs}
    //
    PANAROO_RUN(
        ch_collected_gffs
    )
    ch_versions = ch_versions.mix(PANAROO_RUN.out.versions)

    //
    // MODULE: GENEDISTS prescence-abscence distances
    //
    GENEDISTS(
        PANAROO_RUN.out.rtab
    )
    ch_versions = ch_versions.mix(GENEDISTS.out.versions)

    //
    // MODULE: MashTree
    //
    if (params.mashtree){
        // Get only assemblies from the input and place in a channel per species and cluster
        INPUT_CHECK.out.final_input_files
        .filter{meta, assembly, gff, reference -> meta.has_assembly == true}
        .map{ meta, assembly, gff, reference -> tuple([[species:meta.species, cluster_id:meta.cluster_id], assembly[0]]) } //we need to do assembly [0] since its a tuple, should only have the one file if assembly
        .groupTuple(by: [0])
        .set{ ch_assemblies }

        //Run Mashtree
        MASHTREE(
            ch_assemblies
        )
        ch_versions = ch_versions.mix(MASHTREE.out.versions)
    }

    //
    //MODULE: Get software versions
    //
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name:'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowProcessclusterperspecies.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowProcessclusterperspecies.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(SNIPPY_CLUSTERS.out.snippy_txt.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()

    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
