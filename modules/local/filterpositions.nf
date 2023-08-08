// filter imputation positions accotding to previous imputation performance
process FILTER_POSITIONS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::r-data.table=1.14.8  r-r.utils=2.12.2"
    // TODO: containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-data.table:1.12.2' }"

    input:
    tuple val(meta), path(performance_csv), val(performance_threshold)
    val filter_var

    output:
    tuple val(meta), path("*.tsv") , emit: posfile
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def args       = task.ext.args   ?: ""
    """
    #!/usr/bin/env Rscript

    library("data.table")

    setDTthreads(${task.cpus})

    colnames <- c("chr", "pos", "ref", "alt")
    df <- fread("${performance_csv}", header = TRUE)
    df <- df[${filter_var} > ${performance_threshold}]
    df <- df[,..colnames]

    fwrite(df, "${prefix}.tsv", sep = "\\t", col.names = FALSE)

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
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "strsplit(as.character(R.version['version.string']), ' ')[[1]][3]")
        r-data.table: \$(Rscript -e "utils::packageVersion(\"data.table\")")
    END_VERSIONS
    """
}
