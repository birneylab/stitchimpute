process STITCH_IMPUTATION {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::r-stitch=1.6.10"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-stitch:1.6.10--r43h06b5641_0':
        'biocontainers/r-stitch:1.6.10--r43h06b5641_0' }"

    input:
    tuple val(meta), path(posfile), path(input), path(rdata, stageAs: "RData_in"), val(chromosome_name), val(K), val(nGen)

    output:
    tuple val(meta), path("*.vcf.gz")          , emit: vcf
    tuple val(meta), path("RData", type: "dir"), emit: rdata
    tuple val(meta), path("plots", type: "dir"), emit: plots
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def args        = task.ext.args   ?: ""
    def out_vcf     = "${prefix}.vcf.gz"
    """
    rsync -rL ${rdata}/ RData

    STITCH.R \\
        --chr ${chromosome_name} \\
        --posfile ${posfile} \\
        --output_filename ${out_vcf} \\
        --K ${K} \\
        --nGen ${nGen} \\
        --outputdir . \\
        --nCores ${task.cpus} \\
        --regenerateInput FALSE \\
        --originalRegionName ${chromosome_name} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(R.version[['version.string']], ' ')[[1]][3])")
        r-stitch: \$(Rscript -e "cat(as.character(utils::packageVersion('STITCH')))")
    END_VERSIONS
    """

    stub:
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def args    = task.ext.args   ?: ""
    def out_vcf = "${prefix}.vcf.gz"
    """
    touch ${out_vcf}
    mkdir plots
    mkdir RData

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(R.version[['version.string']], ' ')[[1]][3])")
        r-stitch: \$(Rscript -e "cat(as.character(utils::packageVersion('STITCH')))")
    END_VERSIONS
    """
}
