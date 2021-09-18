#' Create a plot validating an analysis
#'
#' Saves to the `data-raw/` folder
#'
#' @param plans a `redist_plans` object with summary stats
#'
#' @returns the output path, invisibly
#' @export
validate_analysis = function(plans, map) {
    library(ggplot2)
    p_wgts = plot(plans)

    plan_div = plans_diversity(plans, n_max=150) * log(attr(map, "ndists"))
    p_div = qplot(plan_div, bins=I(40), xlab="VI distance", main="Plan diversity")

    p_dev = hist(plans, plan_dev, bins=40) + labs(title="Population deviation")
    p_comp1 = hist(plans, comp_edge, bins=40) + labs(title="Compactness: fraction kept")
    p_comp2 = plot(plans, comp_polsby, geom="boxplot") + labs(title="Compactness: Polsby-Popper")

    if ("county_splits" %in% names(plans)) {
        p_split1 = hist(plans, county_splits) + labs(title="County splits")
    } else p_split1 = patchwork::plot_spacer()
    if ("muni_splits" %in% names(plans)) {
        p_split2 = hist(plans, county_splits) + labs(title="Municipality splits")
    } else p_split2 = patchwork::plot_spacer()

    layout = "
AAABBB
CCCDDD
EEEEEE
FFFGGG"
    p = patchwork::wrap_plots(A=p_wgts, B=p_div, C=p_dev, E=p_comp1,
                          F=p_comp2, G=p_split1, H=p_split2, design=layout) +
        patchwork::plot_annotation(title=str_c(map$state[1], " Validation")) +
        patchwork::plot_layout(guides="collect") &
        theme_bw()
    out_path = here(str_glue("data-raw/{map$state[1]}/validation_{format(Sys.time(), '%Y%m%d_%H%M')}.png"))
    ggsave(out_path, plot=p, height=12, width=10)
    if (rstudioapi::isAvailable()) rstudioapi::viewer(out_path)
    invisible(out_path)
}
