//
// Separate STITCH posfile chromosome-wise
//

include { SEPARATEPOSITIONSBYCHR } from '../../modules/local/separatepositionsbychr'

workflow SPLIT_POSFILE {
    take:
    reference
    stitch_posfile // channel: [mandatory] tuples: [meta, positions_tsv]
    skip_chr       // list   : [optional]  names of chromosome to skip

    main:
    versions = Channel.empty()

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

    // Gather versions of all tools used
    versions.mix ( SEPARATEPOSITIONSBYCHR.out.versions ) .set { versions }

    emit:
    positions       // channel: [meta, positions, chromosome_name]

    versions        // channel: [ versions.yml ]
}
