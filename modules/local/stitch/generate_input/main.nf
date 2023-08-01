process STITCH_GENERATE_INPUT {
    tag "$meta.id"
    label "process_high"

    conda "bioconda::r-stitch=1.6.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0' :
    'biocontainers/r-stitch:1.6.8--r43h06b5641_2' }"

    input:
    tuple(
        val(meta),
        path(cram_files),
        path(crai_files),
        path(posfile),
        path(cramlist),
        path(fasta),
        path(fasta_fai)
    )

    output:
    tuple(
        val(meta),
        path(posfile),
        path("input", type: "dir"),
        path("RData", type: "dir")
    )

    script:
    """
    #!/usr/bin/env Rscript

    STITCH::STITCH(
        tempdir=".",
        chr="${meta.chromosome_name}",
        posfile="${posfile}",
        cramlist="${cramlist}",
        reference="${fasta}",
        nGen=1,
        K=1,
        outputdir=".",
        nCores=${task.cpus},
        generateInputOnly=TRUE
    )
    """
}
