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
    p_wgts = plot(plans) + theme_bw()

    plan_div = plans_diversity(plans, n_max=150) * log(attr(map, "ndists"))
    p_div = qplot(plan_div, bins=I(40), xlab="VI distance", main="Plan diversity") + theme_bw()

    p_dev = hist(plans, plan_dev, bins=40) + labs(title="Population deviation") + theme_bw()
    p_comp1 = hist(plans, comp_edge, bins=40) + labs(title="Compactness: fraction kept") + theme_bw()
    p_comp2 = plot(plans, comp_polsby, geom="boxplot") + labs(title="Compactness: Polsby-Popper") + theme_bw()

    if ("county_splits" %in% names(plans)) {
        p_split1 = hist(plans, county_splits) + labs(title="County splits") + theme_bw()
    } else p_split1 = patchwork::plot_spacer()
    if ("muni_splits" %in% names(plans)) {
        p_split2 = hist(plans, county_splits) + labs(title="Municipality splits") + theme_bw()
    } else p_split2 = patchwork::plot_spacer()

    draws = sample(ncol(as.matrix(subset_sampled(plans))), 3)
    p_ex1 = redist.plot.plans(plans, draws[1], map)
    p_ex2 = redist.plot.plans(plans, draws[2], map)
    p_ex3 = redist.plot.plans(plans, draws[3], map)

    layout = "
AAABBB
CCCDDD
EEEEEE
FFFGGG
HHIIJJ
HHIIJJ"
    p = patchwork::wrap_plots(A=p_wgts, B=p_div, C=p_dev, D=p_comp1,
                          E=p_comp2, F=p_split1, G=p_split2,
                          H=p_ex1, I=p_ex2, J=p_ex3, design=layout) +
        patchwork::plot_annotation(title=str_c(map$state[1], " Validation")) +
        patchwork::plot_layout(guides="collect")
    out_path = here(str_glue("data-raw/{map$state[1]}/validation_{format(Sys.time(), '%Y%m%d_%H%M')}.png"))
    ggsave(out_path, plot=p, height=15, width=10)
    if (rstudioapi::isAvailable()) rstudioapi::viewer(out_path)
    invisible(out_path)
}
