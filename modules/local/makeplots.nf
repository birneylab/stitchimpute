// plot aggregated performance metrics
process MAKE_PLOTS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::r-tidyverse=2.0.0 conda-forge::r-cowplot=1.1.1"
    // TODO: containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-data.table:1.12.2' }"

    input:
    tuple val(meta), path(plotting_data)

    output:
    tuple val(meta), path("*.pdf") , emit: posfile
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def args       = task.ext.args   ?: ""
    """
    #! /usr/bin/env Rscript

    library("tidyverse")
    library("cowplot")

    df <- read_csv("${plotting_data}")

    cdf_plot <- function(col, axis_name){
        if ( "group" %in% colnames(df) ) {
            p <- ggplot(df, aes_string(x = col, color = group))
        } else {
            p <- ggplot(df, aes_string(x = col))
        }

        if ( "${params.mode}" == "grid_search" ) {
            p <- p + labs(color = "STITCH K_nGen")
        } else if ( "${params.mode}" == "snp_set_refinement" ){
            p <- p + labs(color = "Iteration")
        }

        p <- p + stat_ecdf(geom = "step") + theme_cowplot(18)
        sprintf("%s_cumulative_density.pdf", col) %>% ggsave(., p)
    }


    cdf_plot("info_score", "STITCH info score")

    if ( "pearson_r" %in% colnames(df) ){
        cdf_plot("pearson_r", bquote(Pearson~r~"true vs imputed"))
        df["pearson_r2"] <- df["pearson_r"] ** 2
        cdf_plot("pearson_r2", bquote(Pearson~r^2~"true vs imputed"))
    }

    ver_r <- strsplit(as.character(R.version["version.string"]), " ")[[1]][3]
    ver_tidyverse <- utils::packageVersion("tidyverse")
    ver_cowplot <- utils::packageVersion("cowplot")

    system(
        paste(
            "cat <<-END_VERSIONS > versions.yml",
            "\\"${task.process}\\":",
            sprintf("    r-base: %s", ver_r),
            sprintf("    r-tidyverse: %s", ver_tidyverse),
            sprintf("    r-cowplot: %s", ver_cowplot),
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
        r-tidyverse: \$(Rscript -e "utils::packageVersion(\"tidyverse\")")
        r-cowplot: \$(Rscript -e "utils::packageVersion(\"cowplot\")")
    END_VERSIONS
    """
}
