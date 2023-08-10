// generate input for STITCH.
//
// STITCH is an R package with a command line wrapper script that
// however is not part of the conda/biocontainers package. For this reason, I call it from within R.
//
// Generating the input first avoids re-converting the crams to RData every time STITCH
// is re-run.
process STITCH_GENERATEINPUTS {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::r-stitch=1.6.8"
    container "saulpierotti-ebi/r_stitch:1.6.10"

    input:
    tuple val(meta) , path(posfile), val(chromosome_name)
    tuple val(meta2), path(collected_crams), path(collected_crais), path(cramlist)
    tuple val(meta3), path(fasta), path(fasta_fai)

    output:
    tuple val(meta), path("input", type: "dir"), path("RData", type: "dir"), emit: stitch_input
    path "versions.yml"                                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    #!/usr/bin/env Rscript

    library("STITCH")

    STITCH(
        chr = "${chromosome_name}",
        posfile = "${posfile}",
        cramlist = "${cramlist}",
        reference = "${fasta}",
        outputdir = ".",
        nCores = ${task.cpus},
        generateInputOnly = TRUE,
        K = 1,
        nGen = 1${args}
    )

    ver_r <- strsplit(as.character(R.version["version.string"]), " ")[[1]][3]
    ver_stitch <- utils::packageVersion("STITCH")

    system(
        paste(
            "cat <<-END_VERSIONS > versions.yml",
            "\\"${task.process}\\":",
            sprintf("    r-base: %s", ver_r),
            sprintf("    r-stitch: %s", ver_stitch),
            "END_VERSIONS",
            sep = "\\n"
        )
    )
    """

    stub:
    """
    mkdir input
    mkdir RData

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(as.character(R.version[\\"version.string\\"]), \\" \\")[[1]][3])")
        r-stitch: \$(Rscript -e "cat(as.character(utils::packageVersion(\\"STITCH\\")))")
    END_VERSIONS
    """
}
