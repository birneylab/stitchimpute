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
    tuple val(meta), path("input", type: "dir"), path("RData", type: "dir"), emit: stitch_input
    path "versions.yml"                                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STITCH.R \\
        --chr $chromosome_name \\
        --posfile ${posfile} \\
        --cramlist $cramlist \\
        --reference $fasta \\
        --outputdir . \\
        --nCores $task.cpus \\
        --generateInputOnly TRUE \\
        --K 1 \\
        --nGen 1 \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stitch: \$(Rscript -e "utils::packageVersion(\"STITCH\")"))
    END_VERSIONS
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
