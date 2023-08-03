//
// Run a simple imputation workflow
//

include { STITCH_GENERATEINPUTS                   } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION                       } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat/main'

workflow IMPUTATION {
    take:
    positions         // channel [mandatory]: [meta, positions, chromosome_name]
    collected_samples // channel [mandatory]: [meta, collected_crams, collected_crais, stitch_cramlist]
    reference         // channel [mandatory]: [meta, fasta, fasta_fai]

    main:
    versions = Channel.empty()


    STITCH_GENERATEINPUTS ( positions, collected_samples, reference )

    Channel.value ( params.stitch_K    ).set { stitch_K    }
    Channel.value ( params.stitch_nGen ).set { stitch_nGen }

    positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .map {
        meta, positions, chromosome_name, input, rdata, K, nGen ->
        [
            ["id": "chromosome_${chromosome_name}"],
            positions, input, rdata, chromosome_name, K, nGen
        ]
    }
    .set { stitch_input }

    STITCH_IMPUTATION( stitch_input )
    STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    BCFTOOLS_INDEX_STITCH ( stitch_vcf )

    stitch_vcf
    .join( BCFTOOLS_INDEX_STITCH.out.csi )
    .map { meta, vcf, csi -> [[id: "joint_stitch_output"], vcf, csi] }
    .groupTuple ()
    .set { collected_vcfs }

    BCFTOOLS_CONCAT ( collected_vcfs )
    BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    BCFTOOLS_INDEX_JOINT( genotype_vcf )
    BCFTOOLS_INDEX_JOINT.out.csi.set { genotype_index }

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
