//
// Run a simple imputation workflow
//

include { STITCH_GENERATEINPUTS } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION     } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX        } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_MERGE        } from '../../modules/nf-core/bcftools/merge/main'

workflow IMPUTATION {
    take:
    chromosome_names    // channel  : name of chromosomes to run STITCH over
    reads               // tuple    : [meta, cram, crai]
    stitch_posfile      // file     : positions to run the STITCH over
    stitch_cramlist     // file     : basenames of cram files, one per line
    fasta               // file     : reference genome
    fasta_fai           // file     : index for reference genome

    main:
    versions = Channel.empty()

    reads
    .map { meta, cram, crai -> [["id": "collected_samples"], cram, crai] }
    .groupTuple ()
    .combine ( stitch_cramlist )
    .collect () // needed to make it broadcastable
    .set { collected_samples }

    stitch_posfile.combine ( chromosome_names )
    .map {
        posfile, chromosome_name ->
        [
            ["id": chromosome_name, "chromosome_name": chromosome_name],
            posfile,
            chromosome_name
        ]
    }
    .set { positions }

    fasta.combine( fasta_fai )
    .map { fasta, fasta_fai -> [[], fasta, fasta_fai] }
    .collect () // needed to make it broadcastable
    .set { reference }

    STITCH_GENERATEINPUTS (
        positions,
        collected_samples,
        reference
    )

    Channel.value ( params.stitch_K ).set{ stitch_K }
    Channel.value ( params.stitch_nGen ).set{ stitch_nGen }

    STITCH_GENERATEINPUTS.out.stitch_input
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .set { stitch_input }
    STITCH_IMPUTATION( stitch_input )

    STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    BCFTOOLS_INDEX ( stitch_vcf )

    stitch_vcf.view()

    //BCFTOOLS_MERGE(
    //    stitch_vcf.collect(),
    //    fasta.map { [["id": null], it] },
    //    [["id": null], []],
    //    []
    //)

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
