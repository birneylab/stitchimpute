include { SCIKITALLEL_VCFTOZARR                                       } from '../../modules/local/scikitallel/vcftozarr'
include { SCIKITALLEL_VCFTOZARR as SCIKITALLEL_VCFTOZARR_GROUND_TRUTH } from '../../modules/local/scikitallel/vcftozarr'
include { ANNDATA_LOAD_STITCH_VCF_ZARR                                } from '../../modules/local/anndata/load_stitch_vcf_zarr'
include { ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR                          } from '../../modules/local/anndata/load_ground_truth_vcf_zarr'
include { ANNDATA_MERGE_OBS_VARS                                      } from '../../modules/local/anndata/merge_obs_vars'
include { ANNDATA_CALCULATE_PEARSON_R                                 } from '../../modules/local/anndata/calculate_pearson_r'

workflow POSTPROCESSING {
    take:
    genotype_vcf     // channel: [mandatory] [ meta, vcf, vcf_index ]
    ground_truth_vcf // channel: [optional]  [ meta, vcf, vcf_index ]

    main:
    versions = Channel.empty()

    SCIKITALLEL_VCFTOZARR ( genotype_vcf )
    SCIKITALLEL_VCFTOZARR_GROUND_TRUTH ( ground_truth_vcf )
    ANNDATA_LOAD_STITCH_VCF_ZARR ( SCIKITALLEL_VCFTOZARR.out.zarr )
    ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR ( SCIKITALLEL_VCFTOZARR_GROUND_TRUTH.out.zarr )
    ANNDATA_MERGE_OBS_VARS (
        ANNDATA_LOAD_STITCH_VCF_ZARR.out.zarr,
        ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR.out.zarr,
    )
    ANNDATA_CALCULATE_PEARSON_R ( ANNDATA_MERGE_OBS_VARS.out.zarr )

    versions.mix ( SCIKITALLEL_VCFTOZARR.out.versions              ).set { versions }
    versions.mix ( SCIKITALLEL_VCFTOZARR_GROUND_TRUTH.out.versions ).set { versions }
    versions.mix ( ANNDATA_LOAD_STITCH_VCF_ZARR.out.versions       ).set { versions }
    versions.mix ( ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR.out.versions ).set { versions }

    emit:

    versions          // channel: [ versions.yml ]
}
