// load a zarr store derived from the ground truth vcf to an anndata object and save it back to
// zarr
process ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR {
    tag "$meta.id"
    label 'process_high'

    conda "python=3.10.12 anndata=0.9.1 dask=2023.6.1 zarr=2.15.0 scikit-allel=1.3.6 bioconda::tabix=1.11"
    // TODO: add containers
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/r-stitch:1.6.8--r42h37595e4_0':
    //    'biocontainers/r-stitch:1.6.8--r42h37595e4_0' }"

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

    gt = da.from_zarr("${vcf_zarr}/calldata/GT")
    is_biallelic = da.logical_or(gt == 0, gt == 1).all(axis = [1, 2]).compute()
    nucleotides = list("ATCG")
    is_snp = var["ref"].isin(nucleotides) & var["alt"].isin(nucleotides)
    to_keep = np.logical_and(is_biallelic, is_snp).tolist()

    gt = gt[to_keep]
    var = var[to_keep]

    assert da.logical_or(gt == 0, gt == 1).all().compute()
    X = gt.sum(axis = 2).T

    adata = an.AnnData(
        X = X,
        dtype = np.float64,
        var = var,
        obs = pd.DataFrame(index = da.from_zarr("${vcf_zarr}/samples"))
    )

    adata.write_zarr("${prefix}.anndata.zarr")

    ver_anndata = an.__version__
    ver_dask = dask.__version__
    ver_pandas = pd.__version__
    ver_numpy = np.__version__

    os.system(
        "cat <<-END_VERSIONS > versions.yml\\n" +
        "\\"${task.process}\\":\\n" +
        "   python: \$(python --version|cut -d' ' -f2)\\n" +
        f"   anndata: {ver_anndata}\\n" +
        f"   dask: {ver_dask}\\n" +
        f"   pandas: {ver_pandas}\\n" +
        f"   numpy: {ver_numpy}\\n" +
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
        pandas: \$(python -c "import pandas\\nprint(pandas.__version__)")
        numpy: \$(python -c "import pandas\\nprint(numpy.__version__)")
    END_VERSIONS
    """
}
