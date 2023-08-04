//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX         } from '../../modules/nf-core/samtools/faidx'
include { SEPARATEPOSITIONSBYCHR } from '../../modules/local/separatepositionsbychr'

workflow PREPROCESSING {
    take:
    reads     // channel: [mandatory] tuples: [meta, cram, crai]
    fasta     // channel: [mandatory] file:   reference_genome_fasta
    positions // channel: [mandatory] tuples: [meta, positions_tsv]
    skip_chr  // list   : [optional]  names of chromosome to skip

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
    .set { chromosome_names }

    positions
    .combine ( chromosome_names )
    .map {
        meta, positions, chromosome_name ->
        def new_meta = meta.clone()
        new_meta.id = "positions_${chromosome_name}"
        [new_meta, positions, chromosome_name]
    }
    .set{ positions }

    SEPARATEPOSITIONSBYCHR( positions )
    SEPARATEPOSITIONSBYCHR.out.positions
    .join ( positions )
    .map {
        meta, positions_chr, positions_all, chromosome_name ->
        [meta, positions_chr, chromosome_name]
    }
    .set { positions }

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
    versions.mix ( SEPARATEPOSITIONSBYCHR.out.versions ) .set { versions }

    emit:
    collected_samples // channel: [meta, collected_crams, collected_crais, stitch_cramlist]
    reference         // channel: [meta, fasta, fasta_fai]
    positions         // channel: [meta, positions, chromosome_name]

    versions        // channel: [ versions.yml ]
}
