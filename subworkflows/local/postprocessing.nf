include { SCIKITALLEL_VCFTOZARR                                       } from '../../modules/local/scikitallel/vcftozarr'
include { SCIKITALLEL_VCFTOZARR as SCIKITALLEL_VCFTOZARR_GROUND_TRUTH } from '../../modules/local/scikitallel/vcftozarr'
include { ANNDATA_LOAD_STITCH_VCF_ZARR                                } from '../../modules/local/anndata/load_stitch_vcf_zarr'
include { ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR                          } from '../../modules/local/anndata/load_ground_truth_vcf_zarr'
include { ANNDATA_MERGE_OBS_VARS                                      } from '../../modules/local/anndata/merge_obs_vars'
include { ANNDATA_GET_PERFORMANCE                                     } from '../../modules/local/anndata/get_performance.nf'

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

    if ( params.ground_truth_vcf ) {
        ANNDATA_MERGE_OBS_VARS (
            ANNDATA_LOAD_STITCH_VCF_ZARR.out.zarr,
            ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR.out.zarr,
        )
        ANNDATA_GET_PERFORMANCE ( ANNDATA_MERGE_OBS_VARS.out.zarr )

        versions.mix ( ANNDATA_MERGE_OBS_VARS.out.versions ).set { versions }
    } else {
        ANNDATA_GET_PERFORMANCE ( ANNDATA_LOAD_STITCH_VCF_ZARR.out.zarr )
    }

    ANNDATA_GET_PERFORMANCE.out.csv.set { performance }

    versions.mix ( SCIKITALLEL_VCFTOZARR.out.versions              ).set { versions }
    versions.mix ( SCIKITALLEL_VCFTOZARR_GROUND_TRUTH.out.versions ).set { versions }
    versions.mix ( ANNDATA_LOAD_STITCH_VCF_ZARR.out.versions       ).set { versions }
    versions.mix ( ANNDATA_LOAD_GROUND_TRUTH_VCF_ZARR.out.versions ).set { versions }
    versions.mix ( ANNDATA_GET_PERFORMANCE.out.versions            ).set { versions }

    emit:
    performance // channel: [ meta, performance_csv ]

    versions    // channel: [ versions.yml ]
}
