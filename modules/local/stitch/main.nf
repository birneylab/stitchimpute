process STITCH {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::r-stitch=1.6.10"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-stitch:1.6.10--r43h06b5641_0':
        'biocontainers/r-stitch:1.6.10--r43h06b5641_0' }"

    input:
    tuple val(meta) , path(posfile), path(input), path(rdata, stageAs: "RData_in"), val(chromosome_name), val(K), val(nGen)
    tuple val(meta2), path(collected_crams), path(collected_crais), path(cramlist)
    tuple val(meta3), path(fasta), path(fasta_fai)

    output:
    tuple val(meta), path("input", type: "dir") , emit: input
    tuple val(meta), path("RData", type: "dir") , emit: rdata
    tuple val(meta), path("plots", type: "dir") , emit: plots , optional: { generateinput }
    tuple val(meta), path("*.vcf.gz")           , emit: vcf   , optional: { generateinput }
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                        = task.ext.args   ?: ""
    def prefix                      = task.ext.prefix ?: "${meta.id}"
    def generateinput               = task.ext.args.contains( "--generateInputOnly TRUE" )
    def onlyimpute                  = task.ext.args.contains( "--regenerateInput FALSE"  )
    def conditionally_required_args = (
        onlyimpute ?
        "" :
        "--cramlist ${cramlist} --reference ${fasta}"
    )
    def copy_rdata_commmand         = onlyimpute ? "rsync -rL ${rdata}/ RData" : ""
    """
    ${copy_rdata_commmand}

    STITCH.R \\
        --chr ${chromosome_name} \\
        --posfile ${posfile} \\
        --outputdir . \\
        --nCores ${task.cpus} \\
        --K ${K} \\
        --nGen ${nGen} \\
        ${conditionally_required_args} ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(R.version[['version.string']], ' ')[[1]][3])")
        r-stitch: \$(Rscript -e "cat(as.character(utils::packageVersion('STITCH')))")
    END_VERSIONS
    """

    stub:
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def args          = task.ext.args   ?: ""
    def generateinput = task.ext.args.contains( "--generateInputOnly TRUE" )
    """
    mkdir input
    mkdir RData
    ${generateinput ? "" : "mkdir plots"}
    ${generateinput ? "" : "touch ${prefix}.vcf.gz"}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(strsplit(R.version[['version.string']], ' ')[[1]][3])")
        r-stitch: \$(Rscript -e "cat(as.character(utils::packageVersion('STITCH')))")
    END_VERSIONS
    """
}
