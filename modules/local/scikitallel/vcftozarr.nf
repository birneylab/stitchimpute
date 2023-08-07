// convert a vcf file to zarr format
process SCIKITALLEL_VCFTOZARR {
    tag "$meta.id"
    label 'process_high'

    conda "python=3.10.12 anndata=0.9.1 dask=2023.6.1 zarr=2.15.0 scikit-allel=1.3.6 bioconda::tabix=1.11"
    // TODO: add containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

    input:
    tuple val(meta), path(vcf), path(vcf_index)

    output:
    tuple val(meta), path("*.zarr", type: "dir") , emit: zarr
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def args        = task.ext.args   ?: ""
    """
    #!/usr/bin/env python

    import allel
    import os

    allel.vcf_to_zarr(
        input  = "${vcf}",
        output = "${prefix}.zarr",
        fields = "*",
        overwrite = True,
    )

    ver = allel.__version__
    os.system(
        "cat <<-END_VERSIONS > versions.yml\\n" +
        "\\"${task.process}\\":\\n" +
        "    python: \$(python --version|cut -d' ' -f2)\\n" +
        f"    scikit-allel: {ver}\\n" +
        "END_VERSIONS"
    )
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    """
    mkdir ${prefix}.zarr

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version|cut -d' ' -f2)
        scikit-allel: \$(python -c "import allel\\nprint(allel.__version__)")
    END_VERSIONS
    """
}
