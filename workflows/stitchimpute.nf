/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

// Validate input parameters
WorkflowStitchimpute.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory file parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def checkPathParamList = [
    params.input,
    params.fasta,
    params.stitch_posfile
]

for (param in checkPathParamList) if (param) file(param, checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check conditionally mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

switch (params.mode) {

    case "imputation":

        if (!params.stitch_K) {
            error("No value was provided for the parameter stitch_K, which is required for the imputation workflow.")
        }
        if (!params.stitch_nGen) {
            error("No value was provided for the parameter stitch_nGen, which is required for the imputation workflow.")
        }
        if (params.grid_search_params) {
            log.warn("The parameter \"grid_search_params\" is set to but will not be used in the imputation workflow. Set the \"mode\" parameter to \"grid_search\" if you want to perform a parameter search.")
        }
        if (params.snp_filtering_criteria) {
            log.warn("The parameter \"snp_filtering_criteria\" is set to but will not be used in the imputation workflow. Set the \"mode\" parameter to \"snp_set_refinement\" if you want to refine the SNP set.")
        }

        break

    case "grid_search":

        if (params.stitch_K) {
            log.warn("The parameter stitch_K is set but will not be used in the \"grid_search_params\" workflow.")
        }
        if (params.stitch_nGen) {
            log.warn("The parameter stitch_nGen is set but will not be used in the \"grid_search_params\" workflow.")
        }
        if (!params.grid_search_params) {
            error("No value was provided for the parameter \"grid_search_params\", which is required for the grid search workflow.")
        }
        if (params.snp_filtering_criteria) {
            log.warn("The parameter \"snp_filtering_criteria\" is set to but will not be used in the grid search workflow. Set the \"mode\" parameter to \"snp_set_refinement\" if you want to refine the SNP set.")
        }

        break

    case "snp_set_refinement":
        // recursion required for this workflow
        nextflow.preview.recursion = true

        if (!params.stitch_K) {
            error("No value was provided for the parameter stitch_K, which is required for the SNP set refinement workflow.")
        }
        if (!params.stitch_nGen) {
            error("No value was provided for the parameter stitch_nGen, which is required for the SNP set refinement workflow.")
        }
        if (params.grid_search_params) {
            log.warn("The parameter \"grid_search_params\" is set to but will not be used in the SNP set_refinement workflow. Set the \"mode\" parameter to \"snp_set_refinement\" if you want to refine the SNP set.")
        }
        if (!params.snp_filtering_criteria) {
            error("No value was provided for the parameter \"snp_filtering_criteria\", which is required for the snp_set_refinement workflow.")
        }

        break

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { IMPUTATION           } from '../subworkflows/local/imputation'
include { GRID_SEARCH          } from '../subworkflows/local/grid_search'
include { SNP_SET_REFINEMENT   } from '../subworkflows/local/snp_set_refinement'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow STITCHIMPUTE {
    versions = Channel.empty ()

    switch (params.mode) {
        case "imputation":

            //
            // SUBWORKFLOW: run the imputation
            //

            IMPUTATION ()
            versions.mix ( IMPUTATION.out.versions ).set { versions }

            break

        case "grid_search":

            //
            // SUBWORKFLOW: optimise parameters
            //

            GRID_SEARCH ()
            versions.mix ( GRID_SEARCH.out.versions ).set { versions }

            break

        case "snp_set_refinement":

            //
            // SUBWORKFLOW: refine SNP set
            //

            SNP_SET_REFINEMENT ()
            versions.mix ( SNP_SET_REFINEMENT.out.versions ).set { versions }

            break

    }

    CUSTOM_DUMPSOFTWAREVERSIONS (
        versions.unique().collectFile(name: 'collated_versions.yml')
    )
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
