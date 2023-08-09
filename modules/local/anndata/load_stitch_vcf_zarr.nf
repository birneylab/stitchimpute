// load a zarr store derived from a STITCH vcf to an anndata object and save it back to
// zarr
process ANNDATA_LOAD_STITCH_VCF_ZARR {
    tag "$meta.id"
    label 'process_high'

    conda "python=3.10.12 anndata=0.9.1 dask=2023.6.1 zarr=2.15.0 scikit-allel=1.3.6 bioconda::tabix=1.11"
    container "saulpierotti-ebi/python_genomics:1.0"

    input:
    tuple val(meta), path(vcf_zarr)

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
    import pandas as pd
    import numpy as np
    import os

    var = pd.DataFrame(
        dict(
            chr = da.from_zarr("${vcf_zarr}/variants/CHROM").compute(),
            pos = da.from_zarr("${vcf_zarr}/variants/POS").compute(),
            ref = da.from_zarr("${vcf_zarr}/variants/REF").compute(),
            alt = da.from_zarr("${vcf_zarr}/variants/ALT")[:, 0].compute()
        )
    )
    var["snp_id"] = (
        var["chr"].astype(str) + "_" +
        var["pos"].astype(str) + "_" +
        var["ref"].astype(str) + "_" +
        var["alt"].astype(str)
    )

    var.set_index("snp_id", inplace = True)

    X_layers = dict(
        dosage_hard = da.from_zarr("${vcf_zarr}/calldata/GP").argmax(axis = 2).T,
        dosage_soft = da.from_zarr("${vcf_zarr}/calldata/DS").T,
    )

    varm = dict(
        info_score = da.from_zarr("${vcf_zarr}/variants/INFO_SCORE"),
        mean_dosage_hard = X_layers["dosage_hard"].mean(axis = 0),
        mean_dosage_soft = X_layers["dosage_soft"].mean(axis = 0),
        std_dosage_hard = X_layers["dosage_hard"].std(axis = 0),
        std_dosage_soft = X_layers["dosage_soft"].std(axis = 0),
    )

    adata = an.AnnData(
        dtype = np.float64,
        var = var,
        layers = X_layers,
        obs = pd.DataFrame(index = da.from_zarr("${vcf_zarr}/samples")),
        varm = varm
    )

    adata.write_zarr("${prefix}.anndata.zarr")

    ver_anndata = an.__version__
    ver_dask = dask.__version__
    ver_pandas = pd.__version__
    ver_numpy = np.__version__

    os.system(
        "cat <<-END_VERSIONS > versions.yml\\n" +
        "\\"${task.process}\\":\\n" +
        "    python: \$(python --version|cut -d' ' -f2)\\n" +
        f"    anndata: {ver_anndata}\\n" +
        f"    dask: {ver_dask}\\n" +
        f"    pandas: {ver_pandas}\\n" +
        f"    numpy: {ver_numpy}\\n" +
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
        anndata: \$(python -c "import anndata; print(anndata.__version__)")
        dask: \$(python -c "import dask; print(dask.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """
}
