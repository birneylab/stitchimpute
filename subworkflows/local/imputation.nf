//
// Run a simple imputation workflow
//

include { STITCH_GENERATEINPUTS } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION     } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX        } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT       } from '../../modules/nf-core/bcftools/concat/main'

workflow IMPUTATION {
    take:
    positions         // channel [mandatory]: [meta, positions, chromosome_name]
    collected_samples // channel [mandatory]: [meta, collected_crams, collected_crais, stitch_cramlist]
    reference         // channel [mandatory]: [meta, fasta, fasta_fai]

    main:
    versions = Channel.empty()

    //fasta.combine( fasta_fai )
    //.map { fasta, fasta_fai -> [[], fasta, fasta_fai] }
    //.collect () // needed to make it broadcastable
    //.set { reference }

    //STITCH_GENERATEINPUTS (
    //    positions,
    //    collected_samples,
    //    reference
    //)

    //Channel.value ( params.stitch_K ).set{ stitch_K }
    //Channel.value ( params.stitch_nGen ).set{ stitch_nGen }

    //STITCH_GENERATEINPUTS.out.stitch_input
    //.combine ( stitch_K )
    //.combine ( stitch_nGen )
    //.set { stitch_input }
    //STITCH_IMPUTATION( stitch_input )

    //STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    //BCFTOOLS_INDEX ( stitch_vcf )

    //stitch_vcf
    //.join( BCFTOOLS_INDEX.out.csi )
    //.map { meta, vcf, csi -> [[id: "joint_stitch_output"], vcf, csi] }
    //.groupTuple ()
    //.set { collected_vcfs }

    //BCFTOOLS_CONCAT ( collected_vcfs )

    //BCFTOOLS_CONCAT.out.vcf.view()

    //BCFTOOLS_INDEX.out.csi
    //.map { meta,csi -> csi }
    //.collect ()
    //.map { [["id": "stitch_joined_output"], it] }
    //.set { stitch_vcf_index_collected }

    //BCFTOOLS_MERGE(
    //    stitch_vcf_collected.multiple.join ( stitch_vcf_index_collected ),
    //    fasta.map { [["id": null], it] },
    //    [["id": null], []],
    //    []
    //)

    //stitch_vcf_collected
    //.set { single_vcf_output }

    //BCFTOOLS_MERGE.out.merged_variants
    //.concat ( single_vcf_output )
    //.set { vcf }

    //versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    //versions.mix ( STITCH_IMPUTATION.out.versions ) .set { versions }
    //versions.mix ( BCFTOOLS_INDEX.out.versions ) .set { versions }
    //versions.mix ( BCFTOOLS_MERGE.out.versions ) .set { versions }

    //emit:
    //versions   // channel: [ versions.yml   ]
    //vcf        // channel: [ meta, vcf_file ]

}
