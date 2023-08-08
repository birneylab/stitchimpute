// calculate downsampling factor from output of SAMTOOLS_COVERAGE, in order to reach the
// desired coverage level
process GET_DOWNSAMPLE_FACTOR {
    tag "$meta.id"
    label 'process_single'
    debug true

    conda "conda-forge::r-data.table=1.14.8  r-r.utils=2.12.2"
    // TODO: containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-data.table:1.12.2' }"

    input:
    tuple val(meta), path(coverage)
    val desired_depth
    val skip_chr

    output:
    tuple val(meta), path("*.txt"), emit: downsample_factor
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    def excluded_chr = skip_chr ? "c(" + skip_chr.collect { "\"${it}\"" }.join(",") + ")" : "character(0)"
    """
    #!/usr/bin/env Rscript

    library("data.table")

    setDTthreads(${task.cpus})

    df <- fread("${coverage}", sep = "\\t", header = TRUE)
    df <- df[ !(as.character(`#rname`) %in% ${excluded_chr}) ]
    df[, region_length := endpos - startpos]
    original_depth <- df[, sum(meandepth * region_length) / sum(region_length)]
    downsampling_factor <- ${desired_depth} / original_depth

    stopifnot(downsampling_factor < 1)

    fwrite(
        data.table(downsampling_factor),
        "${prefix}.downsampling_factor.txt",
        col.names = FALSE
    )

    ver_r <- strsplit(as.character(R.version["version.string"]), " ")[[1]][3]
    ver_datatable <- utils::packageVersion("data.table")

    system(
        paste(
            "cat <<-END_VERSIONS > versions.yml",
            "\\"${task.process}\\":",
            sprintf("    r-base: %s", ver_r),
            sprintf("    r-data.table: %s", ver_datatable),
            "END_VERSIONS",
            sep = "\\n"
        )
    )
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    """
    touch ${prefix}.downsampling_factor.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "strsplit(as.character(R.version['version.string']), ' ')[[1]][3]")
        r-data.table: \$(Rscript -e "utils::packageVersion(\"data.table\")")
    END_VERSIONS
    """
}
