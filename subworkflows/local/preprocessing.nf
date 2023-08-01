//
// Create cramlist for STITCH and index reference if required
//

include { SAMTOOLS_FAIDX } from '../../modules/nf-core/samtools/faidx'

workflow PREPROCESSING {
    take:
    reads     // channel: [mandatory] tuples: [meta, [cram, crai]]
    fasta     // channel: [mandatory] file:   reference genome
    fasta_fai // channel: [optional]  file:   index for reference genome

    main:
    fasta.map{ fasta -> [ [ id:fasta.baseName ], fasta ] }.set { fasta }
    versions = Channel.empty()

    SAMTOOLS_FAIDX ( fasta, [['id':null], []] )

    reads
        .map{ it[1][0][-1] as String } // string: cram filename without path
        .collectFile ( name:"stitch_cramlist.txt",newLine:true )
        .set { stitch_cramlist }

    // Gather versions of all tools used
    versions.mix ( SAMTOOLS_FAIDX.out.versions ) .set { versions }

    emit:
    versions // channel: [ versions.yml ]
}
