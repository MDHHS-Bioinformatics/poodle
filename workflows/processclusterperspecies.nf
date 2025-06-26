/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowProcessclusterperspecies.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CLEAN_TREE                  } from '../modules/local/cleantree'
include { GENEDISTS                   } from '../modules/local/genedists'
include { SNIPPY_CORE                 } from '../modules/nf-core/snippy/core/main'
include { SNIPPY_RUN                  } from '../modules/nf-core/snippy/run/main'
include { REFERENCE_EVALUATION        } from '../modules/local/referenceevaluation.nf'
include { YAML_REPORT                 } from '../modules/local/report/yamlreport.nf'
include { QUARTO_REPORT               } from '../modules/local/report/quartoreport.nf'

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
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { SNPDISTS as SNPDISTS_SNIPPY  } from '../modules/nf-core/snpdists/main'
include { SNPDISTS as SNPDISTS_GUBBINS } from '../modules/nf-core/snpdists/main'
include { IQTREE                       } from '../modules/nf-core/iqtree/main'
include { GUBBINS                      } from '../modules/nf-core/gubbins/main'
include { SNPSITES                     } from '../modules/nf-core/snpsites/main'
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

    // SUBWORKFLOW: Snippy run and Snippy core (verifying prior results and reference)
    //
    SNIPPY_CLUSTERS(
        INPUT_CHECK.out.final_input_files
    )
    //ch_versions = SNIPPY_CLUSTERS.out.versions

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

        // Output only columns containing exclusively ACGT
        SNPSITES(GUBBINS.out.fasta)
        ch_versions = ch_versions.mix(SNPSITES.out.versions)

        // Get SNP distance matrix
        SNPDISTS_GUBBINS(SNPSITES.out.snp_fasta)
        ch_versions = ch_versions.mix(SNPDISTS_GUBBINS.out.versions)
    }

    //
    // MODULE: Gene-presence abscence with Panaroo
    //
    //Collect GFF files by species and cluster
    INPUT_CHECK.out.final_input_files
    .map{meta, reads, assembly, gff, reference -> tuple([[species:meta.species,cluster_id:meta.cluster_id],gff])}
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
        //INPUT_CHECK.out.final_input_files.view()
        // Get only assemblies from the input and place in a channel per species and cluster
        INPUT_CHECK.out.final_input_files
        .filter{meta, reads, assembly, gff, reference -> meta.has_assembly == true}
        .map{ meta, reads, assembly, gff, reference -> tuple([[species:meta.species, cluster_id:meta.cluster_id], assembly]) }
        .groupTuple(by: [0])
        .set{ ch_assemblies }

        //Run Mashtree
        MASHTREE(
            ch_assemblies
        )
        ch_versions = ch_versions.mix(MASHTREE.out.versions)
    }

    //
    // MODULE: YAML
    //
    if (params.mashtree && params.gubbins) {
        // Channel with finished results
        ch_clusters = SNIPPY_CLUSTERS.out.ref_evaluation
            .join(CLEAN_TREE.out.tre, by: 0)
            .join(SNPDISTS_SNIPPY.out.tsv, by: 0)
            .join(PANAROO_RUN.out.summary, by: 0)
            .join(PANAROO_RUN.out.csv, by: 0)
            .join(PANAROO_RUN.out.rtab, by: 0)
            .join(GENEDISTS.out.tsv, by: 0)
            .join(GUBBINS.out.tree_labelled, by: 0)
            .join(SNPDISTS_GUBBINS.out.tsv, by: 0)
            .join(MASHTREE.out.tree, by: 0)
            .join(MASHTREE.out.matrix, by: 0)
            .map { meta, ref_eval, snptree, snpmatrix,  pan_summary, pan_roary, pan_rtab, pan_genedists, gubtree, gubmatrix,
                    mashtree, mashmatrix ->
                tuple([meta,
                        ref_eval, snptree, snpmatrix,
                        pan_summary, pan_roary, pan_rtab, pan_genedists,
                        gubtree, gubmatrix,
                        mashtree, mashmatrix]) }
        //ch_clusters.view()
        // Create YAML file for reports
        YAML_REPORT(
            ch_clusters
        )

        // Channel to pass the Quarto Notebook
        Channel.value(file(params.poodle_report)).set { ch_qmd }
        Channel.value(file(params.logo_report)).set { ch_logo }

        //
        // MODULE: QUARTO
        //
        QUARTO_REPORT(
            YAML_REPORT.out.files,
            YAML_REPORT.out.yaml,
            ch_qmd,
            ch_logo
        )
        ch_versions = ch_versions.mix(QUARTO_REPORT.out.versions)
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
