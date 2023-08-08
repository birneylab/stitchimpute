//
// Create cramlist for STITCH, index reference fasta, and get chromosome names from fasta
// index
//

include { SAMTOOLS_FAIDX                                             } from '../../modules/nf-core/samtools/faidx'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_GROUND_TRUTH              } from '../../modules/nf-core/bcftools/index'

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
    fasta.join ( SAMTOOLS_FAIDX.out.fai ).collect ().set { reference }

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
