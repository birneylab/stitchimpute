//
// Run a parameter grid search
//

include { SPLIT_POSFILE                           } from '../../subworkflows/local/split_stitch_posfile'
include { STITCH as STITCH_GENERATEINPUTS         } from '../../modules/local/stitch'
include { STITCH as STITCH_IMPUTATION             } from '../../modules/local/stitch'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat'


workflow GRID_SEARCH {
    take:
    collected_samples // channel: [mandatory] [ meta, collected_crams, collected_crais, cramlist ]
    reference         // channel: [mandatory] [ meta, fasta, fasta_fai ]
    stitch_posfile    // channel: [mandatory] [ meta, stitch_posfile ]
    chr_list          // channel: [mandatory] list of chromosomes names

    main:
    versions = Channel.empty()

    SPLIT_POSFILE ( reference, stitch_posfile, chr_list )
    SPLIT_POSFILE.out.positions.set { positions }

    positions
    .map{
        meta, posfile, chromosome_name ->
        [meta, posfile, [], [], chromosome_name, 1, 1]
    }
    .set { stitch_input }

    STITCH_GENERATEINPUTS ( stitch_input, collected_samples, reference )

    Channel.fromPath ( params.grid_search_params )
    .splitCsv( header:true )
    .set { grid_search_params }

    positions
    .join ( STITCH_GENERATEINPUTS.out.input )
    .join ( STITCH_GENERATEINPUTS.out.rdata )
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

    STITCH_IMPUTATION( stitch_input, [null, [], [], []], [null, [], []] )
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
    genotype_vcf.join ( BCFTOOLS_INDEX_JOINT.out.csi ).set { genotype_vcf }

    versions.mix ( SPLIT_POSFILE.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ) .set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ) .set { versions }

    emit:
    genotype_vcf // channel: [ meta, vcf, vcf_index ]

    versions     // channel: [ versions.yml ]

}
