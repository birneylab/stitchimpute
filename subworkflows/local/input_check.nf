//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_cram_channel(it) }
        .set { reads }

    emit:
    reads                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ cram, crai ] ]
def create_cram_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.high_cov   = row.high_cov.toBoolean()

    // add path(s) of the cram and crai file(s) to the meta map
    def cram_meta = []
    if (!file(row.cram).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Cram file does not exist!\n${row.cram}"
    }
    if (!file(row.crai).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Crai file does not exist!\n${row.crai}"
    }
    cram_meta = [ meta, [ file(row.cram), file(row.crai) ] ]
    return cram_meta
}
