// plot aggregated performance metrics
process MAKE_PLOTS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::r-base:4.3.1 conda-forge::r-tidyverse=2.0.0 conda-forge::r-cowplot=1.1.1"
    container "saulpierotti-ebi/r_plotting:0.1"

    input:
    tuple val(meta), path(plotting_data)

    output:
    tuple val(meta), path("*.pdf") , emit: plots
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def args          = task.ext.args   ?: ""
    def plotting_data = "c(" + plotting_data.collect { "\"${it}\"" }.join(",") + ")"
    """
    #! /usr/bin/env Rscript

    library("tidyverse")
    library("cowplot")

    plotting_data_vec <- ${plotting_data}
    df <- read_csv(plotting_data_vec)

    cdf_plot <- function(col, axis_name, limits){
        colq <- enquo(col)

        if ( "group" %in% colnames(df) ) {
            p <- ggplot(df, aes(x = as.numeric(!!colq), color = group))
        } else {
            p <- ggplot(df, aes(x = as.numeric(!!colq)))
        }

        if ( "${params.mode}" == "grid_search" ) {
            p <- p + labs(color = "STITCH K_nGen")
        } else if ( "${params.mode}" == "snp_set_refinement" ){
            p <- p + labs(color = "Iteration")
        }

        p <- p +
            stat_ecdf(geom = "step") +
            theme_cowplot(18) +
            scale_x_continuous(limits = limits) +
            xlab(axis_name)

        sprintf("%s_cumulative_density.pdf", col) %>% ggsave(., p)
    }

    cdf_plot("info_score", "STITCH info score", c(0, 1))

    if ( "pearson_r" %in% colnames(df) ){
        cdf_plot("pearson_r", bquote(Pearson~r~"true vs imputed"), c(-1, 1))
        df["pearson_r2"] <- df["pearson_r"] ** 2
        cdf_plot("pearson_r2", bquote(Pearson~r^2~"true vs imputed"), c(0, 1))
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
    touch info_score_cumulative_density.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(as.character(R.version[\\"version.string\\"]), \\" \\")[[1]][3])")
        r-tidyverse: \$(Rscript -e "cat(as.character(utils::packageVersion(\\"tidyverse\\")))")
        r-cowplot: \$(Rscript -e "cat(as.character(utils::packageVersion(\\"cowplot\\")))")
    END_VERSIONS
    """
}
