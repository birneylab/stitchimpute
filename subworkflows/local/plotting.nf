// Plot the aggregated imputation performance

include { ADD_PERFORMANCE_GROUP } from '../../modules/local/addperformancegroup'
include { MAKE_PLOTS            } from '../../modules/local/makeplots'


workflow PLOTTING {
    take:
    performance // channel: [mandatory] [ meta, performance_csv ]

    main:
    versions = Channel.empty()

    if ( params.mode != "imputation" ) {
        performance.map {
            meta, performance_csv ->

            def String group = null

            switch ( params.mode ) {
                case "grid_search":
                    group = meta.params_comb
                    .collect { k, v -> "${k}_${v}" }
                    .join ( "_" )

                    break

                case "snp_set_refinement":
                    group = meta.iteration

                    break
            }

            [ meta, performance_csv, group ]
        }
        .set { performance }

        ADD_PERFORMANCE_GROUP ( performance )
        ADD_PERFORMANCE_GROUP.out.performance.set { performance }

        versions.mix ( ADD_PERFORMANCE_GROUP.out.versions ).set { versions }
    }

    performance
    .map {
        meta, performance_csv -> [["id": "collected_performance"], performance_csv]
    }
    .groupTuple ()
    .set { performance }

    MAKE_PLOTS ( performance )
    MAKE_PLOTS.out.plots
    .flatMap { meta, plots -> [[meta], plots].combinations() }
    .set { plots }

    versions.mix ( MAKE_PLOTS.out.versions ).set { versions }

    emit:
    plots    // channel: [ pdf_plots ]

    versions // channel: [ versions.yml ]
}
