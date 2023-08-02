process STITCH_IMPUTATION {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::r-stitch=1.6.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
        'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

    input:
    tuple val(meta), path(posfile), path(input), path(RData), val(chromosome_name), val(stitch_args)

    output:
    tuple val(meta), path("*.vcf.gz")          , emit: vcf
    tuple val(meta), path("RData", type: "dir"), emit: rdata
    tuple val(meta), path("plots", type: "dir"), emit: plots
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ? stitch_args + task.ext.args : stitch_args // should be a map of param: value
    def args_str = args ? args.collect { /$it.key=$it.value/ }.join (",") : ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def out_vcf = "${chromosome_name}.vcf.gz"
    def last_comma = args_str ? "," : ""
    """
    #!/usr/bin/env Rscript

    library("STITCH")

    stitch_ver <- utils::packageVersion("STITCH")

    STITCH(
        tempdir=".",
        outputdir=".",
        posfile="${posfile}",
        chr="${chromosome_name}",
        output_filename="${out_vcf}",
        nCores=${task.cpus},
        regenerateInput = FALSE,
        regenerateInputWithDefaultValues = TRUE,
        originalRegionName = "${chromosome_name}"${last_comma}
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
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${out_vcf}
    mkdir plots

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stitch: \$(Rscript -e "utils::packageVersion(\"STITCH\")"))
    END_VERSIONS
    """
}
