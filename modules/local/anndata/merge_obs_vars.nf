// merge two anndata object on the obs and vars axis, returning the intersection as a new
// zarr store
process ANNDATA_MERGE_OBS_VARS {
    tag "$meta.id"
    label 'process_high'

    conda "python=3.10.12 anndata=0.9.1 dask=2023.6.1 zarr=2.15.0 scikit-allel=1.3.6 bioconda::tabix=1.11"
    // TODO: add containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

    input:
    tuple val(meta ), path(adata_zarr_stitch)
    tuple val(meta2), path(adata_zarr_true  )

    output:
    tuple val(meta), path("*.zarr", type: "dir") , emit: zarr
    path "versions.yml"                          , emit: versions

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
    import numpy as np
    import os
    import sys

    sys.path.append("${projectDir}/bin")
    from anndata_utilities import read_dask_anndata

    imputed_adata = read_dask_anndata("${adata_zarr_stitch}")
    truth_adata = read_dask_anndata("${adata_zarr_true}")

    obs_intesect = imputed_adata.obs_names.intersection(truth_adata.obs_names)
    var_intesect = imputed_adata.var_names.intersection(truth_adata.var_names)

    imputed_adata = imputed_adata[obs_intesect, var_intesect]
    truth_adata = truth_adata[obs_intesect, var_intesect]

    def consolidate(dask_dict: dict):
        return {
            key: el.copy() for key, el in dask_dict.items()
        }

    merged = an.AnnData(
        obs = imputed_adata.obs,
        var = imputed_adata.var,
        varm = consolidate(imputed_adata.varm),
        layers = consolidate(imputed_adata.layers),
        dtype = np.float64,
    )
    merged.layers["true_dosage"] = truth_adata.X.copy()

    merged.write_zarr("${prefix}.validation.anndata.zarr")

    ver_anndata = an.__version__
    ver_dask = dask.__version__
    ver_numpy = np.__version__

    os.system(
        "cat <<-END_VERSIONS > versions.yml\\n" +
        "\\"${task.process}\\":\\n" +
        "   python: \$(python --version|cut -d' ' -f2)\\n" +
        f"   anndata: {ver_anndata}\\n" +
        f"   dask: {ver_dask}\\n" +
        f"   numpy: {ver_numpy}\\n" +
        "END_VERSIONS"
    )
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args   = task.ext.args   ?: ""
    """
    mkdir ${prefix}.validation.anndata.zarr

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version|cut -d' ' -f2)
        anndata: \$(python -c "import anndata\\nprint(anndata.__version__)")
        dask: \$(python -c "import dask\\nprint(dask.__version__)")
        numpy: \$(python -c "import pandas\\nprint(numpy.__version__)")
    END_VERSIONS
    """
}
