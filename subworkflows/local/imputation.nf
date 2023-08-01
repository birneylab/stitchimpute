//
// Run a simple imputation workflow
//

include { STITCH_GENERATE_INPUT } from '../../modules/local/stitch/generate_input'

workflow IMPUTATION {
    take:
    reads               // tuple    : [meta, [cram, crai]]
    stitch_cramlist     // file     : basenames of cram files, one per line
    fasta_fai           // file     : reference genome
    fasta               // file     : index for reference genome
    chromosome_names    // channel  : name of chromosomes to run STITCH over

    main:
    reads.view()
    //STITCH_GENERATE_INPUT()
}
