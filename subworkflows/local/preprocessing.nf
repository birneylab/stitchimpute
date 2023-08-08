//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX                                } from '../../modules/nf-core/samtools/faidx'
include { SAMTOOLS_COVERAGE                             } from '../../modules/nf-core/samtools/coverage'
include { SAMTOOLS_VIEW as SAMTOOLS_DOWNSAMPLE          } from '../../modules/nf-core/samtools/view'
include { GET_DOWNSAMPLE_FACTOR                         } from '../../modules/local/getdownsamplefactor'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_GROUND_TRUTH } from '../../modules/nf-core/bcftools/index'

workflow PREPROCESSING {
    take:
    reads        // channel: [mandatory] [ meta, cram, crai ]
    fasta        // channel: [mandatory] [ fasta ]
    skip_chr     // channel: [mandatory] list of chromosomes to skip
    ground_truth // channel: [optional]  [ vcf_file ]

    main:
    versions = Channel.empty()

    fasta.map { fasta -> [ [ id:fasta.baseName ], fasta ] }.set { fasta }
    SAMTOOLS_FAIDX ( fasta, [['id':null], []] )
    fasta.join ( SAMTOOLS_FAIDX.out.fai ).first ().set { reference }

    reference
    .map{ meta, fasta, fasta_fai -> fasta_fai }
    .splitCsv ( sep:"\t" )
    .map { name, length, offset, linebases, linewidth -> name }
    .filter { name -> ! skip_chr.contains ( name ) }
    .collect ()
    .ifEmpty ( ["stub_chr"] )
    .set { chr_list }

    reads
    .map { meta, cram, crai -> cram[-1] as String } // cram name without path
    .collectFile ( name: "stitch_cramlist.txt", newLine:true )
    .set { stitch_cramlist }

    // downsample here
    reads
    .branch {
        meta, cram, crai ->
        high_cov: meta.high_cov
        low_cov : !meta.high_cov
    }
    .set { reads }

    SAMTOOLS_COVERAGE( reads.high_cov )
    GET_DOWNSAMPLE_FACTOR( SAMTOOLS_COVERAGE.out.coverage, 1e-5, skip_chr )
    GET_DOWNSAMPLE_FACTOR.out.downsample_factor
    .splitText( elem: 1 ) { meta, downsample_factor -> [meta, downsample_factor.trim()] }
    .join ( reads.high_cov )
    .map {
        meta, downsample_factor, cram, crai ->
        new_meta = meta.clone()
        new_meta.downsample_factor = downsample_factor
        [new_meta, cram, crai]
    }
    .set { reads_to_downsample }

    SAMTOOLS_DOWNSAMPLE( reads_to_downsample, reference, [] )

    reads.low_cov.mix ( reads.high_cov ).set { reads }

    reads
    .map { meta, cram, crai -> [["id": "collected_samples"], cram, crai] }
    .groupTuple ()
    .combine ( stitch_cramlist )
    .collect () // needed to make it broadcastable
    .set { collected_samples }

    ground_truth.map { [["id": "ground_truth_vcf"], it] }.set { ground_truth }
    BCFTOOLS_INDEX_GROUND_TRUTH ( ground_truth )

    ground_truth
    .join( BCFTOOLS_INDEX_GROUND_TRUTH.out.csi )
    .collect ()
    .set { ground_truth }

    // Gather versions of all tools used
    versions.mix ( SAMTOOLS_FAIDX.out.versions              ) .set { versions }
    versions.mix ( BCFTOOLS_INDEX_GROUND_TRUTH.out.versions ) .set { versions }

    emit:
    collected_samples // channel: [ meta, collected_crams, collected_crais, stitch_cramlist ]
    reference         // channel: [ meta, fasta, fasta_fai ]
    chr_list          // channel: list of chromosomes to consider
    ground_truth      // channel: [ meta, vcf, vcf_index ]

    versions          // channel: [ versions.yml ]
}
