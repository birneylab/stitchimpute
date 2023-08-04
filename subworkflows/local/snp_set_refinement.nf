//
// Refine the set of positions via iterative filtering
//

include { INPUT_CHECK                             } from '../../subworkflows/local/input_check'
include { PREPROCESSING                           } from '../../subworkflows/local/preprocessing'
include { STITCH_GENERATEINPUTS                   } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION                       } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Initialise mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

fasta             = params.fasta          ? Channel.fromPath(params.fasta).collect()          : Channel.empty()
stitch_posfile    = params.stitch_posfile ? Channel.fromPath(params.stitch_posfile).collect() : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Initialise optional parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

skip_chr = params.skip_chr ? params.skip_chr.split( "," ) : []

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Recursion specific parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.mode == "snp_set_refinement") {
    filter_value_list = read_filter_values( params.snp_filtering_criteria )
}


workflow RECURSIVE_ROUTINE {
    take:
    itervar

    main:
    itervar.map {
        meta, positions_list ->
        new_meta = meta.clone()
        new_meta.filter_value = filter_value_list[new_meta.iteration - 1]
        [new_meta, positions_list]
    }
    .set { itervar }

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK ( file(params.input) )
    INPUT_CHECK.out.reads.set { reads }

    //
    // SUBWORKFLOW: index reference genomoe and prepare STITCH inputs
    //
    PREPROCESSING ( reads, fasta, itervar, skip_chr )

    //PREPROCESSING.out.collected_samples.set { collected_samples }
    //PREPROCESSING.out.reference        .set { reference         }
    //PREPROCESSING.out.positions        .set { positions         }

    //STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    //itervar.map{ meta, positions_list -> [meta.iteration, meta.filter_value] }.view()

    itervar.map {
        meta, positions_list ->
        new_meta = meta.clone()
        new_meta.iteration += 1
        [new_meta, positions_list]
    }
    .set { itervar }

    emit:
    itervar
}


workflow SNP_SET_REFINEMENT {
    versions = Channel.empty()

    stitch_posfile.map { [["id": null, "iteration": 1], it] }.collect().set { itervar }

    RECURSIVE_ROUTINE
    .recurse ( itervar )
    .times ( filter_value_list.size() )
}


//
// Groovy functions
//

def read_filter_values ( filepath ) {
    snp_filtering_criteria = new File ( filepath )

    if ( !snp_filtering_criteria.exists() ) {
        error("${params.snp_filtering_criteria} does not point to a valid file")
    }

    def String[] filter_value_list = snp_filtering_criteria
    filter_value_list = filter_value_list
    .findAll { it != "" } // to remove empty lines that can be present at the end of file
    .collect { Float.parseFloat( it ) }

    return(filter_value_list)
}
