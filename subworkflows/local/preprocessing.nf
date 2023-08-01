//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX } from '../../modules/nf-core/samtools/faidx'

workflow PREPROCESSING {
    take:
    reads     // channel: [mandatory] tuples: [meta, [cram, crai]]
    fasta     // channel: [mandatory] file:   reference genome

    main:
    fasta.map{ fasta -> [ [ id:fasta.baseName ], fasta ] }.set { fasta }
    versions = Channel.empty()

    SAMTOOLS_FAIDX ( fasta, [['id':null], []] )

    SAMTOOLS_FAIDX.out.fai
        .map{ it[1] } // remove meta
        .splitCsv ( sep:"\t" )
        .map { it[0] } // select chromosome name
        .set { chromosome_names }

    reads
        .map{ it[1][0][-1] as String } // string: cram filename without path
        .collectFile ( name:"stitch_cramlist.txt",newLine:true )
        .set { stitch_cramlist }

    // Gather versions of all tools used
    versions.mix ( SAMTOOLS_FAIDX.out.versions ) .set { versions }

    emit:
    stitch_cramlist                     // file     : basenames of cram files, one per line
    fasta_fai = SAMTOOLS_FAIDX.out.fai  // file     : index for reference genome
    chromosome_names                    // channel  : name of chromosomes to run STITCH over

    versions // channel: [ versions.yml ]
}
