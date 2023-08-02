process STITCH_GENERATEINPUTS {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::r-stitch=1.6.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
        'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

    input:
    tuple val(meta) , path(posfile), val(chromosome_name)
    tuple val(meta2), path(collected_crams), path(collected_crais), path(cramlist)
    tuple val(meta3), path(fasta), path(fasta_fai)

    output:
    tuple val(meta), path("${posfile}"), path("input", type: "dir"), path("RData", type: "dir"), val(chromosome_name), emit: stitch_input
    path "versions.yml"                                                                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args // should be a map of param: value
    def args_str = args ? args.collect { /$it.key=$it.value/ }.join (",") : ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def last_comma = args_str ? "," : ""
    """
    #!/usr/bin/env Rscript

    library("STITCH")

    stitch_ver <- utils::packageVersion("STITCH")

    STITCH(
        tempdir=".",
        chr="${chromosome_name}",
        posfile="${posfile}",
        cramlist="${cramlist}",
        reference="${fasta}",
        nGen=1,
        K=1,
        outputdir=".",
        nCores=${task.cpus},
        generateInputOnly=TRUE${last_comma}
        ${args_str}
    )

    system(
        paste(
            "cat <<-END_VERSIONS > versions.yml",
            "\\"${task.process}\\":",
            sprintf("    stitch: %s", stitch_ver),
            "END_VERSIONS",
            sep = "\n"
        )
    )
    """

    stub:
    """
    mkdir input
    mkdir RData

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stitch: \$(Rscript -e "utils::packageVersion(\"STITCH\")"))
    END_VERSIONS
    """
}
