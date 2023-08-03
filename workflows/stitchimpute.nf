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

fasta          = params.fasta          ? Channel.fromPath(params.fasta).collect()          : Channel.empty()
stitch_posfile = params.stitch_posfile ? Channel.fromPath(params.stitch_posfile).collect() : Channel.empty()

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
        if (params.stitch_grid_search) {
            log.warn("The parameter \"stitch_grid_search\" is set to but will not be used in the imputation workflow. Set the \"mode\" parameter to \"grid_search\" if you want to perform a parameter search.")
        }
        break

    case "grid_search":
        if (params.stitch_K) {
            log.warn("The parameter stitch_K is set but will not be used in the \"grid_search\" workflow.")
        }
        if (params.stitch_nGen) {
            log.warn("The parameter stitch_nGen is set but will not be used in the \"grid_search\" workflow.")
        }
        if (!params.stitch_grid_search) {
            error("No value was provided for the parameter \"stitch_grid_search\", which is required for the grid_search workflow.")
        }
        break

    case "snp_set_refinement":
        break

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Initialise optional parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

skip_chr = params.skip_chr ? params.skip_chr.split( "," ) : []

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK   } from '../subworkflows/local/input_check'
include { PREPROCESSING } from '../subworkflows/local/preprocessing'
include { IMPUTATION    } from '../subworkflows/local/imputation'
include { GRID_SEARCH   } from '../subworkflows/local/grid_search'

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

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK ( file(params.input) )
    INPUT_CHECK.out.reads.set { reads }

    //
    // SUBWORKFLOW: index reference genomoe and prepare STITCH imputats
    //
    PREPROCESSING ( reads, fasta, stitch_posfile, skip_chr )

    PREPROCESSING.out.collected_samples.set { collected_samples }
    PREPROCESSING.out.reference        .set { reference         }
    PREPROCESSING.out.positions        .set { positions         }

    //
    // Collate and dump software versions
    //
    versions.mix ( INPUT_CHECK.out.versions   ).set { versions }
    versions.mix ( PREPROCESSING.out.versions ).set { versions }


    switch (params.mode) {
        case "imputation":

            //
            // SUBWORKFLOW: run the imputation
            //

            IMPUTATION ( positions, collected_samples, reference )
            versions.mix ( IMPUTATION.out.versions ).set { versions }

            break

        case "grid_search":

            GRID_SEARCH  ( positions, collected_samples, reference )
            //versions.mix ( GRID_SEARCH.out.versions ).set { versions }

            break

        case "snp_set_refinement":

            error("Branch not yet implemented")

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
