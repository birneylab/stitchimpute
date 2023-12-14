# ![birneylab/stitchimpute](docs/images/birneylab-stitchimpute_name_light.png#gh-light-mode-only) ![birneylab/stitchimpute](docs/images/birneylab-stitchimpute_name_dark.png#gh-dark-mode-only)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**birneylab/stitchimpute** is a bioinformatics pipeline that uses [STITCH](https://doi.org/10.1038/ng.3594) for imputing genotypes from low-coverage NGS data in a population.
It can also help in the selection of the ideal parameters for the imputation, and in the refinement of the SNP set used.
It can compare the imputation results against some ground truth (i.e. high-coverage samples) for performance evaluation and parameter/SNP set refinement.

**Disclaimer**: this pipeline uses the nf-core template but it is not part of nf-core itself.

![birneylab/stitchimpute](docs/images/birneylab-stitchimpute_metro_map.png)

1. Downsample high-coverage cram files ([`samtools`](http://www.htslib.org/doc/samtools.html); _optional_)
2. Run joint imputation with STITCH on high and low coverage cram files ([`STITCH`](https://doi.org/10.1038/ng.3594))
3. Compare imputation results to ground truth variants ([`glimpse2 concordance`](https://odelaneau.github.io/GLIMPSE/docs/documentation/concordance/); _optional_)
4. Plot imputation performance stats ([`ggplot2`](https://ggplot2.tidyverse.org/))

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,cram,crai
/path/to/sample1.cram,/path/to/sample1.cram.crai
/path/to/sample2.cram,/path/to/sample2.cram.crai
```

Each row represents a sample with its associated cram file and crai file.

Now, you can run the pipeline using:

```bash
nextflow run birneylab/stitchimpute \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

> For more details and further functionality, please refer to the [usage documentation](./docs/usage.md) and the [parameter documentation](./docs/parameters.md).

<!--
> TODO: add docs
> For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/stitchimpute/usage) and the [parameter documentation](https://nf-co.re/stitchimpute/parameters).
-->

## Pipeline output

<!--
To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/stitchimpute/results) tab on the nf-core website pipeline page.
-->

For more details about the output files and reports, please refer to the
[output documentation](./docs/output.md).

## Credits

<!--
nf-core/stitchimpute was originally written by Saul Pierotti.
-->

> birneylab/stitchimpute was originally written by Saul Pierotti.

<!--
> We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#stitchimpute` channel](https://nfcore.slack.com/channels/stitchimpute) (you can join with [this invite](https://nf-co.re/join/slack)).
-->

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](./CITATIONS.md) file.

The main citation for `birneylab/stitchimpute` is:

> **Genotype imputation in F2 crosses of inbred lines**
>
> Saul Pierotti, Bettina Welz, Tomas Fitzgerald, Joachim Wittbrodt, Ewan Birney
>
> _bioR$\chi$iv._ 2023 Dec 12. doi: [10.1101/2023.12.12.571258](https://doi.org/10.1101/2023.12.12.571258)

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
