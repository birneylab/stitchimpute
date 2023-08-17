//
// Refine the set of positions via iterative filtering
//

include { SPLIT_POSFILE                           } from '../../subworkflows/local/split_stitch_posfile'
include { POSTPROCESSING                          } from '../../subworkflows/local/postprocessing'
include { STITCH as STITCH_GENERATEINPUTS         } from '../../modules/local/stitch'
include { STITCH as STITCH_IMPUTATION             } from '../../modules/local/stitch'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_STITCH } from '../../modules/nf-core/bcftools/index'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_JOINT  } from '../../modules/nf-core/bcftools/index'
include { BCFTOOLS_CONCAT                         } from '../../modules/nf-core/bcftools/concat'
include { FILTER_POSITIONS                        } from '../../modules/local/filterpositions'

// workflow-specific variables

filter_var = params.ground_truth_vcf ? (params.filter_var ?: "pearson_r"): "info_score"

//
// Recursive subworkflow: takes only value channels
//
// Use first() when a recursive channel needs to be treated as constant

workflow RECURSIVE_ROUTINE {
    take:
    collected_samples // channel: [mandatory] [ meta, collected_crams, collected_crais, cramlist ]
    reference         // channel: [mandatory] [ meta, fasta, fasta_fai ]
    stitch_posfile    // channel: [mandatory] [ meta, stitch_posfile ]
    chr_list          // channel: [mandatory] list of chromosomes names
    filter_value_list // channel: [mandatory] list of filter values
    genotype_vcf      // channel: [mandatory] [ meta, vcf, vcf_index ]
    ground_truth_vcf  // channel: [mandatory] [ meta, vcf, vcf_index ]
    niter             // channel: [mandatory] total number of iterations
    performance       // channel: [mandatory] [ meta, performance_csv ]

    versions          // channel: [mandatory] [ versions.yml ]

    main:
    chr_list.first().map { it.size() }.set { nchr }
    nchr
    .combine ( niter.first() )
    .flatMap { nchr, niter -> (1..nchr) * niter }
    .set { counter }

    stitch_posfile
    .combine( filter_value_list.first() )
    .map {
        meta, posfile, filter_value_list ->
        def new_meta = meta.clone()
        new_meta.curr_filter_value = filter_value_list[meta.iteration]
        new_meta.iteration         = meta.iteration + 1
        curr_iteration             = new_meta.iteration
        [new_meta, posfile]
    }
    .set { stitch_posfile }

    Channel.value ( params.stitch_K    ).set { stitch_K    }
    Channel.value ( params.stitch_nGen ).set { stitch_nGen }

    SPLIT_POSFILE ( reference.first(), stitch_posfile, chr_list.first() )
    SPLIT_POSFILE.out.positions.set { positions }

    positions
    .map{
        meta, posfile, chromosome_name ->
        [meta, posfile, [], [], chromosome_name, 1, 1]
    }
    .set { stitch_input }

    STITCH_GENERATEINPUTS ( stitch_input, collected_samples.first(), reference.first() )

    positions
    .join ( STITCH_GENERATEINPUTS.out.input )
    .join ( STITCH_GENERATEINPUTS.out.rdata )
    .combine ( stitch_K )
    .combine ( stitch_nGen )
    .map {
        meta, positions, chromosome_name, input, rdata, K, nGen ->
        [
            [
                "id"                   : "chromosome_${chromosome_name}",
                "publish_dir_subfolder": "iteration_${meta.iteration}"  ,
                "curr_filter_value"    : meta.curr_filter_value         ,
                "iteration"            : meta.iteration                 ,
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

    STITCH_IMPUTATION( stitch_input, [null, [], [], []], [null, [], []] )
    STITCH_IMPUTATION.out.vcf.set { stitch_vcf }
    BCFTOOLS_INDEX_STITCH ( stitch_vcf )

    stitch_vcf.join( BCFTOOLS_INDEX_STITCH.out.csi )
    .map {
        meta, vcf, csi ->
        def new_meta = meta.clone()
        new_meta.id = "joint_stitch_output"
        [new_meta, vcf, csi]
    }
    .set { stitch_vcf }

    stitch_vcf
    .combine ( nchr )
    .merge   ( counter )
    // workaround since I cannot use groupTuple in recursion
    .buffer { meta, vcf, csi, nchr, counter -> counter == nchr }
    .map {
        buf ->
        def metas  = buf.collect { meta, vcf, csi, nchr, counter -> meta }.unique ()
        def vcfs   = buf.collect { meta, vcf, csi, nchr, counter -> vcf  }.unique ()
        def csis   = buf.collect { meta, vcf, csi, nchr, counter -> csi  }.unique ()
        def nchrs  = buf.collect { meta, vcf, csi, nchr, counter -> nchr }.unique ()

        assert metas.size() == 1
        assert nchrs.size() == 1

        def meta = metas[0]
        def nchr = nchrs[0]

        assert vcfs .size() == nchr
        assert csis .size() == nchr


        def ret = [meta, vcfs, csis]

        return(ret)
    }
    .set { collected_vcfs }

    BCFTOOLS_CONCAT ( collected_vcfs )
    BCFTOOLS_CONCAT.out.vcf.set { genotype_vcf }
    BCFTOOLS_INDEX_JOINT( genotype_vcf )
    genotype_vcf.join ( BCFTOOLS_INDEX_JOINT.out.csi ).set { genotype_vcf }

    POSTPROCESSING( genotype_vcf, ground_truth_vcf.first() )
    POSTPROCESSING.out.performance.set { performance }

    performance
    .map {
        meta, performance_csv ->
        def new_meta = meta.clone()
        new_meta.id = "stitch_posfile"
        [new_meta, performance_csv, meta.curr_filter_value]
    }
    .set { performance }
    FILTER_POSITIONS ( performance, filter_var )
    FILTER_POSITIONS.out.posfile.set { stitch_posfile_filtered }

    performance
    .map { meta, performance_csv, filter_value -> [meta, performance_csv] }
    .set { performance }

    versions.mix ( SPLIT_POSFILE.out.versions         ).set { versions }
    versions.mix ( STITCH_GENERATEINPUTS.out.versions ).set { versions }
    versions.mix ( STITCH_IMPUTATION.out.versions     ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_STITCH.out.versions ).set { versions }
    versions.mix ( BCFTOOLS_CONCAT.out.versions       ).set { versions }
    versions.mix ( BCFTOOLS_INDEX_JOINT.out.versions  ).set { versions }
    versions.mix ( POSTPROCESSING.out.versions        ).set { versions }

    emit:
    collected_samples       // channel: [ meta, collected_crams, collected_crais, cramlist ]
    reference               // channel: [ meta, fasta, fasta_fai ]
    stitch_posfile_filtered // channel: [ meta, stitch_posfile ]
    chr_list                // channel: list of chromosomes names
    filter_value_list       // channel: list of filter values
    genotype_vcf            // channel: [ meta, vcf, vcf_index ]
    ground_truth_vcf        // channel: [ meta, vcf, vcf_index ]
    niter                   // channel: total number of iterations
    performance             // channel: [ meta, performance_csv ]

    versions                // channel: [ versions.yml ]
}

//
// Wrapper around the recursive part
//

workflow SNP_SET_REFINEMENT {
    take:
    collected_samples // channel: [mandatory] [ meta, collected_crams, collected_crais, cramlist ]
    reference         // channel: [mandatory] [ meta, fasta, fasta_fai ]
    stitch_posfile    // channel: [mandatory] [ meta, stitch_posfile ]
    chr_list          // channel: [mandatory] list of chromosomes names
    ground_truth_vcf  // channel: [optional]  [ meta, vcf, vcf_index ]

    main:
    versions = Channel.empty().collect()

    // will collect the output of each recursion
    genotype_vcf = Channel.empty().collect()
    performance  = Channel.empty().collect()

    stitch_posfile.map {
        meta, stitch_posfile ->
        new_meta = meta.clone()
        new_meta.iteration = 0
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
        ground_truth_vcf.ifEmpty([]),
        niter,
        performance,
        versions,
    ).times ( niter )

    RECURSIVE_ROUTINE.out.genotype_vcf.set { genotype_vcf }
    RECURSIVE_ROUTINE.out.performance .set { performance  }

    versions.mix( RECURSIVE_ROUTINE.out.versions ).set { versions }

    emit:
    genotype_vcf // channel: [ meta, performance_csv ]
    performance  // channel: [ meta, vcf, vcf_index ]

    versions     // channel: [ versions.yml ]
}


// read a iteration-specific filter values to a list and return it with the total number
// of iterations to perform
def read_filter_values ( filepath ) {
    def snp_filtering_criteria = new File ( filepath )

    if ( !snp_filtering_criteria.exists() ) {
        error("${params.snp_filtering_criteria} does not point to a valid file")
    }

    def String[] filter_value_list = snp_filtering_criteria

    filter_value_list = filter_value_list
    .findAll { it != "" } // to remove empty lines that can be present at the end of file
    .collect { Float.parseFloat( it ) }

    def niter = filter_value_list.size()

    log.info(
        "Running SNP set refinement with ${niter} iteration${niter > 1 ? "s" : ""} and using the following filter values: ${filter_value_list}. Filtering will be done on the ${filter_var} values."
    )

    return ( [filter_value_list, niter] )
}
