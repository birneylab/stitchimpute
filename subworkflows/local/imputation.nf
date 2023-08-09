//
// Run a simple imputation workflow
//

include { SPLIT_POSFILE                           } from '../../subworkflows/local/split_stitch_posfile'
include { STITCH_GENERATEINPUTS                   } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION                       } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat/main'


workflow IMPUTATION {
    take:
    collected_samples // channel: [mandatory] [ meta, collected_crams, collected_crais, cramlist ]
    reference         // channel: [mandatory] [ meta, fasta, fasta_fai ]
    stitch_posfile    // channel: [mandatory] [ meta, stitch_posfile ]
    chr_list          // channel: [mandatory] list of chromosomes names

    main:
    versions = Channel.empty()

    SPLIT_POSFILE ( reference, stitch_posfile, chr_list )
    SPLIT_POSFILE.out.positions.set { positions }

    STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    Channel.value ( params.stitch_K    ).set { stitch_K    }
    Channel.value ( params.stitch_nGen ).set { stitch_nGen }

    positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .map {
        meta, positions, chromosome_name, input, rdata, K, nGen ->
        [
            [
                "id"                   : "chromosome_${chromosome_name}",
                "publish_dir_subfolder": ""                             ,
            ],
            positions, input, rdata, chromosome_name, K, nGen
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
        [["id": "joint_stitch_output", "publish_dir_subfolder": ""], vcf, csi]
    }
    .groupTuple ()
    .set { collected_vcfs }

    BCFTOOLS_CONCAT ( collected_vcfs )
    BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    BCFTOOLS_INDEX_JOINT( genotype_vcf )
    genotype_vcf.join ( BCFTOOLS_INDEX_JOINT.out.csi ).set { genotype_vcf }

    versions.mix ( SPLIT_POSFILE.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ).set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ).set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ).set { versions }

    emit:
    genotype_vcf // channel: [ meta, vcf, vcf_index ]

    versions     // channel: [ versions.yml ]

}
