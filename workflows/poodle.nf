/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowPoodle.initialise(params, log)

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

include { CLEAN_TREE as SNIPPY_TREE   } from '../modules/local/cleantree'
include { CLEAN_TREE as GUBBINS_TREE  } from '../modules/local/cleantree'
include { GENEDISTS                   } from '../modules/local/genedists'
include { LINKAGES as LINKAGES_SNIPPY } from '../modules/local/linkages.nf'
include { LINKAGES as LINKAGES_GUBBINS} from '../modules/local/linkages.nf'
include { CONSTANTSITES               } from '../modules/local/constantsites/main'
include { YAML_BOTH                   } from '../modules/local/report/yaml_both.nf'
include { YAML_GUB_ONLY               } from '../modules/local/report/yaml_gub_only.nf'
include { YAML_MASH_ONLY              } from '../modules/local/report/yaml_mash_only.nf'
include { YAML_NEITHER                } from '../modules/local/report/yaml_neither.nf'
include { QUARTO_BOTH                 } from '../modules/local/report/quarto_both.nf'
include { QUARTO_GUB_ONLY             } from '../modules/local/report/quarto_gub_only.nf'
include { QUARTO_MASH_ONLY            } from '../modules/local/report/quarto_mash_only.nf'
include { QUARTO_NEITHER              } from '../modules/local/report/quarto_neither.nf'

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
include { SNIPPY_CORE                  } from '../modules/nf-core/snippy/core/main'
include { SNIPPY_RUN                   } from '../modules/nf-core/snippy/run/main'
include { SNPDISTS as SNPDISTS_SNIPPY  } from '../modules/nf-core/snpdists/main'
include { SNPDISTS as SNPDISTS_GUBBINS } from '../modules/nf-core/snpdists/main'
include { IQTREE as IQTREE_SNIPPY      } from '../modules/nf-core/iqtree/main'
include { IQTREE as IQTREE_GUBBINS     } from '../modules/nf-core/iqtree/main'
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

workflow POODLE {

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
    ch_versions = SNIPPY_CLUSTERS.out.versions

    //
    // MODULE: Core SNP Distances
    //
    SNPDISTS_SNIPPY(
        SNIPPY_CLUSTERS.out.aln
    )
    ch_versions = ch_versions.mix(SNPDISTS_SNIPPY.out.versions.first())

    //
    // MODULE: Core SNP Linkages
    //
    ch_snp_report_dists = SNPDISTS_SNIPPY.out.tsv
    .join(SNIPPY_CLUSTERS.out.snippy_txt)

    LINKAGES_SNIPPY(
        ch_snp_report_dists
    )
    ch_versions = ch_versions.mix(LINKAGES_SNIPPY.out.versions.first())

    //
    // MODULE: Output count of constant sites (suitable for IQ-TREE -fconst)
    //
    CONSTANTSITES(
        SNIPPY_CLUSTERS.out.clean_full_aln
    )
    ch_versions = ch_versions.mix(CONSTANTSITES.out.versions.first())

    // Convert constant sites file to value
    const_ch = CONSTANTSITES.out.constant_sites.map { meta, p -> tuple(meta, p.text.trim())}

    //
    // MODULE: Create core-SNP phylogeny
    //
    // Join number 
    ch_aln_sites = SNIPPY_CLUSTERS.out.aln
    .join(const_ch, by: 0)

    IQTREE_SNIPPY(ch_aln_sites)
    ch_versions = ch_versions.mix(IQTREE_SNIPPY.out.versions)

    //
    // MODULE: Remove reference and root at midpoint
    //
    SNIPPY_TREE(IQTREE_SNIPPY.out.phylogeny)
    ch_versions = ch_versions.mix(SNIPPY_TREE.out.versions)

    //
    // MODULE: Gubbins
    //
    if (params.gubbins) {

        ch_clean_aln_sites = SNIPPY_CLUSTERS.out.clean_full_aln
        .join(const_ch, by: 0)

        GUBBINS(ch_clean_aln_sites)
        ch_versions = ch_versions.mix(GUBBINS.out.versions)

        // Output only columns containing exclusively ACGT
        SNPSITES(GUBBINS.out.fasta)
        ch_versions = ch_versions.mix(SNPSITES.out.versions)

        // Get SNP distance matrix
        SNPDISTS_GUBBINS(SNPSITES.out.snp_fasta)
        ch_versions = ch_versions.mix(SNPDISTS_GUBBINS.out.versions)
        
        // MODULE: Recombination filtered SNP Linkages
        ch_gub_report_dists = SNPDISTS_GUBBINS.out.tsv
        .join(SNIPPY_CLUSTERS.out.snippy_txt)

        LINKAGES_GUBBINS(
            ch_gub_report_dists
        )
        ch_versions = ch_versions.mix(LINKAGES_GUBBINS.out.versions.first())

        // Join SNP aln with constant sites 
        ch_aln_sites_gub = SNPSITES.out.snp_fasta
        .join(const_ch, by: 0)

        // Make filtered-recommbination SNP Tree
        IQTREE_GUBBINS(ch_aln_sites_gub)
        ch_versions = ch_versions.mix(IQTREE_GUBBINS.out.versions)

        // Midpoint rooting and removing reference
        GUBBINS_TREE(IQTREE_GUBBINS.out.phylogeny)
        ch_versions = ch_versions.mix(GUBBINS_TREE.out.versions)
    }

    //
    // MODULE: Gene-presence abscence with Panaroo
    //
    // Collect GFF files by species and cluster
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
    // GENERATING REPORTS BASED ON DIFFERENT CASES
    // Provide the QMDs + logo
    Channel.value(file(params.qmd_both    )).set { ch_qmd_both     }
    Channel.value(file(params.qmd_gubonly )).set { ch_qmd_gubonly  }
    Channel.value(file(params.qmd_mashonly)).set { ch_qmd_mashonly }
    Channel.value(file(params.qmd_neither )).set { ch_qmd_neither  }
    Channel.value(file(params.logo_report )).set { ch_logo         }

    // BOTH
    if (params.gubbins && params.mashtree) {
        ch_clusters_both = LINKAGES_SNIPPY.out.linkages
        .join(SNIPPY_TREE.out.tre,         by: 0)
        .join(SNPDISTS_SNIPPY.out.tsv,     by: 0)
        .join(PANAROO_RUN.out.summary,     by: 0)
        .join(PANAROO_RUN.out.csv,         by: 0)
        .join(PANAROO_RUN.out.rtab,        by: 0)
        .join(GENEDISTS.out.tsv,           by: 0)
        .join(GUBBINS_TREE.out.tre,        by: 0)
        .join(SNPDISTS_GUBBINS.out.tsv,    by: 0)
        .join(MASHTREE.out.tree,           by: 0)
        .join(MASHTREE.out.matrix,         by: 0)
        .map { meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists, gubtree, gubmatrix, mashtree, mashmatrix ->
            tuple(meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists, gubtree, gubmatrix, mashtree, mashmatrix)
        }
        
        YAML_BOTH(ch_clusters_both )
        QUARTO_BOTH(
        YAML_BOTH.out.files, YAML_BOTH.out.yaml,
        ch_qmd_both, ch_logo
        )
        ch_versions = ch_versions.mix(QUARTO_BOTH.out.versions)
    }

    // GUBBINS ONLY
    if (params.gubbins && !params.mashtree) {
        ch_clusters_gub = LINKAGES_SNIPPY.out.linkages
        .join(SNIPPY_TREE.out.tre,          by: 0)
        .join(SNPDISTS_SNIPPY.out.tsv,     by: 0)
        .join(PANAROO_RUN.out.summary,     by: 0)
        .join(PANAROO_RUN.out.csv,         by: 0)
        .join(PANAROO_RUN.out.rtab,        by: 0)
        .join(GENEDISTS.out.tsv,           by: 0)
        .join(GUBBINS_TREE.out.tre,        by: 0)
        .join(SNPDISTS_GUBBINS.out.tsv,      by: 0)
        .map { meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists, gubtree, gubmatrix ->
            tuple(meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists, gubtree, gubmatrix)
        }
        YAML_GUB_ONLY( ch_clusters_gub )
        QUARTO_GUB_ONLY(
        YAML_GUB_ONLY.out.files, YAML_GUB_ONLY.out.yaml,
        ch_qmd_gubonly, ch_logo
        )
       ch_versions = ch_versions.mix(QUARTO_GUB_ONLY.out.versions)
    }

    // MASH ONLY
    if (!params.gubbins && params.mashtree) {
        ch_clusters_mash = LINKAGES_SNIPPY.out.linkages
        .join(SNIPPY_TREE.out.tre,          by: 0)
        .join(SNPDISTS_SNIPPY.out.tsv,     by: 0)
        .join(PANAROO_RUN.out.summary,     by: 0)
        .join(PANAROO_RUN.out.csv,         by: 0)
        .join(PANAROO_RUN.out.rtab,        by: 0)
        .join(GENEDISTS.out.tsv,           by: 0)
        .join(MASHTREE.out.tree,             by: 0)
        .join(MASHTREE.out.matrix,           by: 0)
        .map { meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists,
                mashtree, mashmatrix ->
            tuple(meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists,
                mashtree, mashmatrix)
        }
        YAML_MASH_ONLY(ch_clusters_mash)
        QUARTO_MASH_ONLY(
        YAML_MASH_ONLY.out.files, YAML_MASH_ONLY.out.yaml,
        ch_qmd_mashonly, ch_logo
        )
        ch_versions = ch_versions.mix(QUARTO_MASH_ONLY.out.versions)
    }

    // NEITHER
    if (!params.gubbins && !params.gubbins) {
        ch_clusters_core = LINKAGES_SNIPPY.out.linkages
        .join(SNIPPY_TREE.out.tre,          by: 0)
        .join(SNPDISTS_SNIPPY.out.tsv,     by: 0)
        .join(PANAROO_RUN.out.summary,     by: 0)
        .join(PANAROO_RUN.out.csv,         by: 0)
        .join(PANAROO_RUN.out.rtab,        by: 0)
        .join(GENEDISTS.out.tsv,           by: 0)
        .map { meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists ->
            tuple(meta, ref_eval, snptree, snpmatrix, pan_summary, pan_roary, pan_rtab, pan_genedists)
        }
        YAML_NEITHER(  ch_clusters_core )
        QUARTO_NEITHER(
        YAML_NEITHER.out.files, YAML_NEITHER.out.yaml,
        ch_qmd_neither, ch_logo
        )
        ch_versions = ch_versions.mix(QUARTO_NEITHER.out.versions)
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
    workflow_summary    = WorkflowPoodle.paramsSummaryMultiqc(workflow, summary_params)
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
