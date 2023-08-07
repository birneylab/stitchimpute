// calculate pearson correlation SNP-wise for true and imputed dosage. Zarr store is
// modified in place
process ANNDATA_CALCULATE_PEARSON_R {
    tag "$meta.id"
    label 'process_high'

    conda "python=3.10.12 anndata=0.9.1 dask=2023.6.1 zarr=2.15.0 scikit-allel=1.3.6 bioconda::tabix=1.11"
    // TODO: add containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

    input:
    tuple val(meta), path(adata_zarr)

    output:
    tuple val(meta), path(adata_zarr, type: "dir") , emit: zarr
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def args        = task.ext.args   ?: ""
    """
    #! /usr/bin/env python

    import anndata as an
    import dask
    import dask.array as da
    import os
    import sys

    sys.path.append("${workflow.projectDir}/bin")
    from anndata_utilities import read_dask_anndata
    from dask_utilities import slicewise_pearson_r

    adata = read_dask_anndata("${adata_zarr}")

    adata.varm["pearson_r"] = slicewise_pearson_r(
        Y_true = adata.layers["true_dosage"],
        Y_pred = adata.layers["dosage_${params.correlation_imputed_dosage_type}"],
        axis = 0,
    )

    da.to_zarr(
        adata.varm["pearson_r"],
        "${adata_zarr}/varm/pearson_r",
        overwrite = True
    )
    ver_anndata = an.__version__
    ver_dask = dask.__version__

    os.system(
        "cat <<-END_VERSIONS > versions.yml\\n" +
        "\\"${task.process}\\":\\n" +
        "   python: \$(python --version|cut -d' ' -f2)\\n" +
        f"   anndata: {ver_anndata}\\n" +
        f"   dask: {ver_dask}\\n" +
        "END_VERSIONS"
    )
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    """
    mkdir ${prefix}.anndata.zarr

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version|cut -d' ' -f2)
        anndata: \$(python -c "import anndata\\nprint(anndata.__version__)")
        dask: \$(python -c "import dask\\nprint(dask.__version__)")
    END_VERSIONS
    """
}
