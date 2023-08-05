//
// Refine the set of positions via iterative filtering
//

include { SPLIT_POSFILE                           } from '../../subworkflows/local/split_stitch_posfile'
include { STITCH_GENERATEINPUTS                   } from '../../modules/local/stitch/generateinputs'
include { STITCH_IMPUTATION                       } from '../../modules/local/stitch/imputation'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat/main'

//
// Recursive subworkflow: takes only value channels
//
// Use first() when a recursive channel needs to be treated as constant

workflow RECURSIVE_ROUTINE {
    take:
    collected_samples
    reference
    stitch_posfile
    chr_list
    filter_value_list

    genotype_vcf
    genotype_index

    versions

    main:
    stitch_posfile
    .combine( filter_value_list.first() )
    .map {
        meta, posfile, filter_value_list ->
        def curr_filter_value = filter_value_list[meta.iteration - 1]
        [meta, posfile, curr_filter_value]
    }
    .set { stitch_posfile }

    //
    // filter code goes here
    //

    stitch_posfile
    .map { meta, posfile, filter_value -> [meta, posfile] }
    .set { stitch_posfile }

    Channel.value ( params.stitch_K    ).set { stitch_K    }
    Channel.value ( params.stitch_nGen ).set { stitch_nGen }

    SPLIT_POSFILE ( reference.first(), stitch_posfile, chr_list.first() )
    SPLIT_POSFILE.out.positions.set { positions }

    STITCH_GENERATEINPUTS ( positions, collected_samples.first(), reference.first() )

    positions.join ( STITCH_GENERATEINPUTS.out.stitch_input )
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .map {
        meta, positions, chromosome_name, input, rdata, K, nGen ->
        [
            [
                "id"                   : "chromosome_${chromosome_name}",
                "publish_dir_subfolder": "iteration_${meta.iteration}"  ,
            ],
            positions,
            input,
            rdata,
            chromosome_name,
            K,
            nGen,
        ]
    }
    .set { stitch_input }

    STITCH_IMPUTATION( stitch_input )
    STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    BCFTOOLS_INDEX_STITCH ( stitch_vcf )

    stitch_vcf
    .join( BCFTOOLS_INDEX_STITCH.out.csi )
    .map {
        meta, vcf, csi ->
        def new_meta = meta.clone()
        new_meta.id = "joint_stitch_output"
        [new_meta, vcf, csi]
    }
    .groupTuple ()
    .set { collected_vcfs }

    BCFTOOLS_CONCAT ( collected_vcfs )
    BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    BCFTOOLS_INDEX_JOINT( genotype_vcf )
    BCFTOOLS_INDEX_JOINT.out.csi.set { genotype_index }

    stitch_posfile.map {
        meta, posfile ->
        new_meta = meta.clone()
        new_meta.iteration = meta.iteration + 1
        [new_meta, posfile]
    }
    .set { stitch_posfile }

    versions.mix ( SPLIT_POSFILE.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ).set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ).set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ).set { versions }

    emit:
    collected_samples
    reference
    stitch_posfile
    chr_list
    filter_value_list

    genotype_vcf
    genotype_index

    versions
}

//
// Wrapper around the recursive part
//

workflow SNP_SET_REFINEMENT {
    take:
    collected_samples
    reference
    stitch_posfile
    chr_list

    main:
    versions = Channel.empty().collect()

    // will collect the output of each recursion
    genotype_vcf   = Channel.empty().collect()
    genotype_index = Channel.empty().collect()

    stitch_posfile.map {
        meta, stitch_posfile ->
        new_meta = meta.clone()
        new_meta.iteration = 1
        [new_meta, stitch_posfile]
    }.set { stitch_posfile }

    (filter_value_list, niter) = read_filter_values ( params.snp_filtering_criteria )

    RECURSIVE_ROUTINE
    .recurse (
        collected_samples,
        reference,
        stitch_posfile,
        chr_list,
        filter_value_list,
        genotype_vcf,
        genotype_index,
        versions,
    ).times ( niter )

    RECURSIVE_ROUTINE.out.genotype_index.set { genotype_index }
    RECURSIVE_ROUTINE.out.genotype_vcf  .set { genotype_vcf   }

    versions.mix( RECURSIVE_ROUTINE.out.versions ).set { versions }

    emit:
    genotype_vcf   // channel: [ meta, vcf_file ]
    genotype_index // channel: [ meta, csi ]

    versions       // channel: [ versions.yml ]
}


// read a iteration-specific filter values to a list and return it with the total number
// of iterations to perform
def read_filter_values ( filepath ) {
    snp_filtering_criteria = new File ( filepath )

    if ( !snp_filtering_criteria.exists() ) {
        error("${params.snp_filtering_criteria} does not point to a valid file")
    }

    def String[] filter_value_list = snp_filtering_criteria

    filter_value_list = filter_value_list
    .findAll { it != "" } // to remove empty lines that can be present at the end of file
    .collect { Float.parseFloat( it ) }

    def niter = filter_value_list.size()

    log.info(
        "Running SNP set refinement with ${niter} iteration${niter > 1 ? "s" : ""} and using the following filter values: ${filter_value_list}"
    )

    return ( [filter_value_list, niter] )
}
