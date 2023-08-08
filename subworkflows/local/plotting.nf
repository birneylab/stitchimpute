// Plot the aggregated imputation performance

include { MAKE_PLOTS            } from '../../modules/local/makeplots'
include { ADD_PERFORMANCE_GROUP } from '../../modules/local/addperformancegroup'


workflow PLOTTING {
    take:
    performance // channel: [mandatory] [ meta, performance_csv ]

    main:
    versions = Channel.empty()

    if ( params.mode != "imputation" ) {
        performance.map {
            meta, performance_csv ->

            switch ( params.mode ) {
                case "grid_search":
                    def group = meta.params_comb
                case "snp_set_refinement":
                    def group = meta.iteration
            }

            assert group

            [ meta, performance_csv, group ]
        }
        .view()
        .set { performance }

        ADD_PERFORMANCE_GROUP( performance )
        ADD_PERFORMANCE_GROUP.out.performance.set { performance }
    }

    performance.view()

    emit:
    versions    // channel: [ versions.yml ]
}
