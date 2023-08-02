//
// Run a simple imputation workflow
//

include { STITCH_GENERATEINPUTS } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION } from '../../modules/local/stitch/imputation'

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

    Channel.of( ["K": 2, "nGen": 1] ).set { stitch_args }

    reads.groupTuple ().map{
        metas, crams, crais -> [[], crams, crais]
    }
    .combine ( stitch_cramlist )
    .set { collected_samples }

    stitch_posfile.combine ( chromosome_names )
    .map {
        posfile, chromosome_name -> [["id": chromosome_name], posfile, chromosome_name]
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

    STITCH_GENERATEINPUTS.out.stitch_input.combine ( stitch_args ).set { stitch_input }
    STITCH_IMPUTATION( stitch_input )

    versions.mix ( STITCH_GENERATEINPUTS.out.versions ) .set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions ) .set { versions }

    emit:
    versions // channel: [ versions.yml ]
}
