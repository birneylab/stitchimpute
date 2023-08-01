//
// Run a simple imputation workflow
//

include { STITCH_GENERATE_INPUT } from '../../modules/local/stitch/generate_input'

workflow IMPUTATION {
    take:
    chromosome_names    // channel  : name of chromosomes to run STITCH over
    reads               // tuple    : [meta, cram, crai]
    stitch_posfile      // file     : positions to run the STITCH over
    stitch_cramlist     // file     : basenames of cram files, one per line
    fasta               // file     : reference genome
    fasta_fai           // file     : index for reference genome

    main:
    chromosome_names
        .combine ( reads.map{ it[1,2] } ) // remove meta
        .groupTuple()
        .map{
            chromosome_name, cram_files, crai_files ->
            [
                ["chromosome_name": chromosome_name, id: "chromosome_name"],
                cram_files,
                crai_files
            ]
        }
        .combine ( stitch_posfile )
        .combine ( stitch_cramlist )
        .combine ( fasta )
        .combine ( fasta_fai )
        .set{ stitch_generate_input_in_ch }

    STITCH_GENERATE_INPUT ( stitch_generate_input_in_ch )
}
