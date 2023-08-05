//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX } from '../../modules/nf-core/samtools/faidx'

workflow PREPROCESSING {
    take:
    reads     // channel: [mandatory] [ meta, cram, crai ]
    fasta     // channel: [mandatory] [ fasta ]
    skip_chr  // channel: [mandatory] list of chromosomes to skip

    main:
    versions = Channel.empty()

    fasta.map { fasta -> [ [ id:fasta.baseName ], fasta ] }.set { fasta }
    SAMTOOLS_FAIDX ( fasta, [['id':null], []] )
    fasta.join ( SAMTOOLS_FAIDX.out.fai ).collect ().set { reference }

    reference
    .map{ meta, fasta, fasta_fai -> fasta_fai }
    .splitCsv ( sep:"\t" )
    .map { name, length, offset, linebases, linewidth -> name }
    .filter { name -> ! skip_chr.contains ( name ) }
    .collect ()
    .set { chr_list }

    reads
    .map { meta, cram, crai -> cram[-1] as String } // cram name without path
    .collectFile (name: "stitch_cramlist.txt", newLine:true)
    .set { stitch_cramlist }

    reads
    .map { meta, cram, crai -> [["id": "collected_samples"], cram, crai] }
    .groupTuple ()
    .combine ( stitch_cramlist )
    .collect () // needed to make it broadcastable
    .set { collected_samples }


    // Gather versions of all tools used
    versions.mix ( SAMTOOLS_FAIDX.out.versions         ) .set { versions }

    emit:
    collected_samples // channel: [ meta, collected_crams, collected_crais, stitch_cramlist ]
    reference         // channel: [ meta, fasta, fasta_fai ]
    chr_list          // channel: list of chromosomes to consider

    versions          // channel: [ versions.yml ]
}
