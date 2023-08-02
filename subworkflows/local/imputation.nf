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

    reads.groupTuple ().map{
        metas, crams, crais -> [[], crams, crais]
    }
    .combine ( stitch_cramlist )
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

    STITCH_IMPUTATION.out.vcf
    .map { meta,vcf -> vcf }
    .collect ()
    .map { [["id": "stitch_joined_output"], it] }
    .branch { // BCFTOOLS_MERGE fails with a single file
        multiple: it[1].size() >  1
        single  : it[1].size() == 1
    }
    .set { stitch_vcf_collected }

    BCFTOOLS_INDEX ( stitch_vcf_collected.multiple )
    BCFTOOLS_INDEX.out.csi
    .map { meta,csi -> csi }
    .collect ()
    .map { [["id": "stitch_joined_output"], it] }
    .set { stitch_vcf_index_collected }

    BCFTOOLS_MERGE(
        stitch_vcf_collected.multiple.join ( stitch_vcf_index_collected ),
        fasta.map { [["id": null], it] },
        [["id": null], []],
        []
    )

    stitch_vcf_collected
    .set { single_vcf_output }

    BCFTOOLS_MERGE.out.merged_variants
    .concat ( single_vcf_output )
    .set { vcf }

    versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX.out.versions ) .set { versions }
    versions.mix ( BCFTOOLS_MERGE.out.versions ) .set { versions }

    emit:
    versions   // channel: [ versions.yml   ]
    vcf        // channel: [ meta, vcf_file ]

}
