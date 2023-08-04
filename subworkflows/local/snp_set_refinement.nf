//
// Refine the set of positions via iterative filtering
//

include { STITCH_GENERATEINPUTS                   } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION                       } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat/main'


//snp_filtering_criteria = new File ( params.snp_filtering_criteria )
//
//if ( !snp_filtering_criteria.exists() ) {
//    error("${params.snp_filtering_criteria} does not point to a valid file")
//}
//
//print(snp_filtering_criteria)

//workflow RECURSIVE_ROUTINE {
//    take:
//    positions
//    collected_samples
//    reference
//    filter_value
//
//    main:
//
//}

workflow SNP_SET_REFINEMENT {
    take:
    positions         // channel [mandatory]: [meta, positions, chromosome_name]
    collected_samples // channel [mandatory]: [meta, collected_crams, collected_crais, stitch_cramlist]
    reference         // channel [mandatory]: [meta, fasta, fasta_fai]

    main:
    versions = Channel.empty()



    //STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    //Channel.fromPath ( params.stitch_grid_search )
    //.splitCsv( header:true )
    //.set { stitch_grid_search_params }

    //positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    //.combine ( stitch_grid_search_params )
    //.map {
    //    meta, positions, chromosome_name, input, rdata, stitch_grid_search_params ->
    //    [
    //        [
    //            "id"                   : "chromosome_${chromosome_name}"                                          ,
    //            "publish_dir_subfolder": "K_${stitch_grid_search_params.K}_nGen_${stitch_grid_search_params.nGen}",
    //            "params_comb"          : stitch_grid_search_params                                                ,
    //        ],
    //        positions,
    //        input,
    //        rdata,
    //        chromosome_name,
    //        stitch_grid_search_params.K,
    //        stitch_grid_search_params.nGen,
    //    ]
    //}
    //.set { stitch_input }

    //STITCH_IMPUTATION( stitch_input )
    //STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    //BCFTOOLS_INDEX_STITCH ( stitch_vcf )

    //stitch_vcf
    //.join( BCFTOOLS_INDEX_STITCH.out.csi )
    //.map {
    //    meta, vcf, csi ->
    //    def new_meta = meta.clone()
    //    new_meta.id = "joint_stitch_output"
    //    [new_meta, vcf, csi]
    //}
    //.groupTuple ()
    //.set { collected_vcfs }

    //BCFTOOLS_CONCAT ( collected_vcfs )
    //BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    //BCFTOOLS_INDEX_JOINT( genotype_vcf )
    //BCFTOOLS_INDEX_JOINT.out.csi.set { genotype_index }

    //versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    //versions.mix ( STITCH_IMPUTATION.out.versions     ) .set { versions }
    //versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ) .set { versions }
    //versions.mix ( BCFTOOLS_CONCAT.out.versions       ) .set { versions }
    //versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ) .set { versions }

    //emit:
    //genotype_vcf   // channel: [meta, vcf_file]
    //genotype_index // channel: [meta, csi]

    //versions       // channel: [versions.yml]

}
