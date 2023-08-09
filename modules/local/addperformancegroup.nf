process ADD_PERFORMANCE_GROUP {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::r-data.table=1.14.8  r-r.utils=2.12.2"
    // TODO: containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-data.table:1.12.2' }"

    input:
    tuple val(meta), path(performance_csv), val(group)

    output:
    tuple val(meta), path("*.csv.gz"), emit: performance
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    """
    #!/usr/bin/env Rscript

    library("data.table")

    setDTthreads(${task.cpus})

    df <- fread("${performance_csv}", header = TRUE)
    df[, group := "${group}"]

    fwrite(df, "${prefix}.addperformancegroup.csv.gz")

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
    touch ${prefix}.addperformancegroup.csv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(as.character(R.version[\\"version.string\\"]), \\" \\")[[1]][3])")
        r-data.table: \$(Rscript -e "cat(as.character(utils::packageVersion(\\"data.table\\")))")
    END_VERSIONS
    """
}
