//
// Run a parameter grid search
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

fasta          = params.fasta          ? Channel.fromPath(params.fasta).collect()          : Channel.empty()
stitch_posfile = params.stitch_posfile ? Channel.fromPath(params.stitch_posfile).collect() : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Initialise optional parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

skip_chr = params.skip_chr ? params.skip_chr.split( "," ) : []


workflow GRID_SEARCH {
    versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK ( file(params.input) )
    INPUT_CHECK.out.reads.set { reads }

    //
    // SUBWORKFLOW: index reference genomoe and prepare STITCH imputats
    //
    stitch_posfile.map { [["id": null], it] }.set { stitch_posfile }
    PREPROCESSING ( reads, fasta, stitch_posfile, skip_chr )

    PREPROCESSING.out.collected_samples.set { collected_samples }
    PREPROCESSING.out.reference        .set { reference         }
    PREPROCESSING.out.positions        .set { positions         }

    STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    Channel.fromPath ( params.grid_search_params )
    .splitCsv( header:true )
    .set { grid_search_params }

    positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    .combine ( grid_search_params )
    .map {
        meta, positions, chromosome_name, input, rdata, grid_search_params ->
        [
            [
                "id"                   : "chromosome_${chromosome_name}"                            ,
                "publish_dir_subfolder": "K_${grid_search_params.K}_nGen_${grid_search_params.nGen}",
                "params_comb"          : grid_search_params                                         ,
            ],
            positions,
            input,
            rdata,
            chromosome_name,
            grid_search_params.K,
            grid_search_params.nGen,
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

    versions.mix ( INPUT_CHECK.out.versions           ).set { versions }
    versions.mix ( PREPROCESSING.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ) .set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ) .set { versions }

    emit:
    genotype_vcf   // channel: [meta, vcf_file]
    genotype_index // channel: [meta, csi]

    versions       // channel: [versions.yml]

}
