//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX                                             } from '../../modules/nf-core/samtools/faidx'
include { SAMTOOLS_SAMPLES                                           } from '../../modules/local/samtools/samples'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_GROUND_TRUTH              } from '../../modules/nf-core/bcftools/index'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_GROUND_TRUTH              } from '../../modules/nf-core/bcftools/query'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_GROUND_TRUTH_SAMPLE_NAMES } from '../../modules/nf-core/bcftools/query'

workflow PREPROCESSING {
    take:
    reads            // channel: [mandatory] [ meta, cram, crai ]
    fasta            // channel: [mandatory] [ fasta ]
    skip_chr         // channel: [mandatory] list of chromosomes to skip
    ground_truth_vcf // channel: [optional]  [ vcf_file ]

    main:
    versions = Channel.empty()

    fasta.map { fasta -> [ [ id:fasta.baseName ], fasta ] }.set { fasta }
    SAMTOOLS_FAIDX ( fasta, [['id':null], []] )
    fasta.join ( SAMTOOLS_FAIDX.out.fai ).collect ().set { reference }

    reference
    .map{ meta, fasta, fasta_fai -> fasta_fai }
    .splitCsv ( sep:"\t" )
    .map { name, length, offset, linebases, linewidth -> name }
    .filter { name -> ! skip_chr.contains ( name ) }
    .collect ()
    .set { chr_list }

    reads
    .map { meta, cram, crai -> cram[-1] as String } // cram name without path
    .collectFile ( name: "stitch_cramlist.txt", newLine:true )
    .set { stitch_cramlist }

    reads
    .map { meta, cram, crai -> [["id": "collected_samples"], cram, crai] }
    .groupTuple ()
    .combine ( stitch_cramlist )
    .collect () // needed to make it broadcastable
    .set { collected_samples }

    ground_truth_vcf.map { [["id": "ground_truth_vcf"], it] }.set { ground_truth_vcf }
    BCFTOOLS_INDEX_GROUND_TRUTH ( ground_truth_vcf )

    ground_truth_vcf
    .join( BCFTOOLS_INDEX_GROUND_TRUTH.out.csi )
    .set { ground_truth_vcf }

    BCFTOOLS_QUERY_GROUND_TRUTH              ( ground_truth_vcf, [], [], [] )
    BCFTOOLS_QUERY_GROUND_TRUTH_SAMPLE_NAMES ( ground_truth_vcf, [], [], [] )

    reads
    .branch {
        high_cov:  it[0].high_cov
        low_cov : !it[0].high_cov
    }
    .set { reads }

    reads.high_cov
    .map { meta, cram, crai -> [["id": "ground_truth_samples"], cram, crai] }
    .groupTuple ()
    .set { collected_ground_truth_reads }

    SAMTOOLS_SAMPLES( collected_ground_truth_reads )

    // Gather versions of all tools used
    versions.mix ( SAMTOOLS_FAIDX.out.versions ) .set { versions }

    emit:
    collected_samples // channel: [ meta, collected_crams, collected_crais, stitch_cramlist ]
    reference         // channel: [ meta, fasta, fasta_fai ]
    chr_list          // channel: list of chromosomes to consider

    versions          // channel: [ versions.yml ]
}
