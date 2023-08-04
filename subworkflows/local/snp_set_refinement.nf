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


//
// Recursive subworkflow: takes only value channels
//
// NOTE: use merge instead of combine otherwise it combines the full recursion tree

workflow RECURSIVE_ROUTINE {
    take:
    itervar  // channel: [meta, stitch_poslist]

    versions // channel: [versions.yml]

    main:
    itervar.map {
        meta, positions_list ->
        new_meta = meta.clone()
        new_meta.filter_value = filter_value_list[new_meta.iteration - 1]
        [new_meta, positions_list]
    }
    .set { itervar }

    Channel.value ( params.stitch_K    ).set { stitch_K    }
    Channel.value ( params.stitch_nGen ).set { stitch_nGen }

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK ( file(params.input) )
    INPUT_CHECK.out.reads.set { reads }

    //
    // SUBWORKFLOW: index reference genomoe and prepare STITCH inputs
    //
    PREPROCESSING ( reads, fasta, itervar, skip_chr )

    PREPROCESSING.out.collected_samples.set { collected_samples }
    PREPROCESSING.out.reference        .set { reference         }
    PREPROCESSING.out.positions        .set { positions         }

    STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .map {
        meta, positions, chromosome_name, input, rdata, K, nGen ->
        [
            [
                "id"                   : "chromosome_${chromosome_name}",
                "publish_dir_subfolder": "iteration_${meta.iteration}"  ,
            ],
            positions,
            input,
            rdata,
            chromosome_name,
            K,
            nGen,
        ]
    }
    .set { stitch_input }

    STITCH_IMPUTATION( stitch_input )
    STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    BCFTOOLS_INDEX_STITCH ( stitch_vcf )

    stitch_vcf
    .join( BCFTOOLS_INDEX_STITCH.out.csi )
    .map {
        meta, vcf, csi ->
        def new_meta = meta.clone()
        new_meta.id = "joint_stitch_output"
        [new_meta, vcf, csi]
    }
    .groupTuple ()
    .set { collected_vcfs }

    BCFTOOLS_CONCAT ( collected_vcfs )
    BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    BCFTOOLS_INDEX_JOINT( genotype_vcf )
    BCFTOOLS_INDEX_JOINT.out.csi.set { genotype_index }

    itervar.map {
        meta, positions ->
        new_meta = meta.clone()
        new_meta.iteration += 1
        [new_meta, positions]
    }
    .set { itervar }

    versions.mix ( INPUT_CHECK.out.versions           ).set { versions }
    versions.mix ( PREPROCESSING.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ).set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ).set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ).set { versions }

    emit:
    itervar  // channel: [meta, stitch_poslist]

    versions // channel: [versions.yml]
}

//
// Wrapper around the recursive part
//

workflow SNP_SET_REFINEMENT {
    versions = Channel.empty().collect()

    stitch_posfile.map { [["id": null, "iteration": 1], it] }.collect().set { itervar }

    RECURSIVE_ROUTINE
    .recurse ( itervar, versions )
    .times ( filter_value_list.size() )

    versions.mix( RECURSIVE_ROUTINE.out.versions ).set { versions }

    emit:
    versions // channel: [versions.yml]
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
