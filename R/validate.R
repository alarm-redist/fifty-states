#' Create a plot validating an analysis
#'
#' Saves to the `data-raw/` folder
#'
#' @param plans a `redist_plans` object with summary stats
#'
#' @returns the output path, invisibly
#' @export
validate_analysis <- function(plans, map) {
    library(ggplot2)
    p_wgts <- plot(plans) + theme_bw()

    plan_div <- plans_diversity(plans, n_max = 150)
    p_div <- dplyr::tibble(div = plan_div) |>
      ggplot2::ggplot() +
      ggplot2::geom_histogram(ggplot2::aes(x = div), bins = 40) +
      ggplot2::labs(x = "VI distance", title = "Plan diversity") +
      ggplot2::theme_bw()

    p_dev <- hist(plans, plan_dev, bins = 40) + labs(title = "Population deviation") + theme_bw()
    p_comp1 <- hist(plans, comp_edge, bins = 40) + labs(title = "Compactness: fraction kept") + theme_bw()
    p_comp2 <- plot(plans, comp_polsby, geom = "boxplot") + labs(title = "Compactness: Polsby-Popper") + theme_bw()

    if ("comp_bbox_reock" %in% names(plans)) {
        p_comp3 <- plot(plans, comp_bbox_reock, geom = "boxplot") +
          labs(title = "Compactness: Bounding Box Reock") +
          theme_bw()
    } else {
        p_comp3 <- patchwork::plot_spacer()
    }

    if ("county_splits" %in% names(plans)) {
        p_split1 <- hist(plans, county_splits) + labs(title = "County splits") + theme_bw()
    } else {
      p_split1 <- patchwork::plot_spacer()
    }
    if ("muni_splits" %in% names(plans)) {
        p_split2 <- hist(plans, muni_splits) + labs(title = "Municipality splits") + theme_bw()
    } else {
      p_split2 <- patchwork::plot_spacer()
    }
    if ("total_county_splits" %in% names(plans)) {
        p_split3 <- hist(plans, total_county_splits) +
          labs(title = "Total county splits") +
          theme_bw()
    } else {
        p_split3 <- patchwork::plot_spacer()
    }
    if ("total_muni_splits" %in% names(plans)) {
        p_split4 <- hist(plans, total_muni_splits) +
          labs(title = "Total municipality splits") +
          theme_bw()
    } else {
        p_split4 <- patchwork::plot_spacer()
    }

    st <- map$state[1]
    enac_sum <- plans |>
        filter(draw == attr(map, "existing_col")) |>
        # TODO: match with what gets plotted
        select(district, comp_polsby, vap_white, vap_black, total_vap) |>
        mutate(minority = (total_vap - vap_white) / (total_vap)) |>
        mutate(
            dist_lab = district,
            minority_rank = rank(minority), # ascending order
            compact_rank = rank(comp_polsby),
        )

    # add label
    p_comp2 <-  p_comp2 +
        geom_text(data = enac_sum,
                  aes(x = compact_rank,
                      label = district), # vjust = "inward" is more proper but at the edges
                  vjust = 3,
                  y = Inf,
                  size = 2.5,
                  fontface = "bold",
                  lineheight = 0.8,
                  alpha = 0.8,
                  color = "red")

    p_vra = plans |>
        mutate(minority = (total_vap - vap_white) / total_vap) |>
        plot(minority, geom="boxplot") +
        # add label
        geom_text(data = enac_sum,
                  aes(x = minority_rank,
                      label = district),
                  vjust = 3,
                  y = Inf,
                  size = 2.5,
                  fontface = "bold",
                  lineheight = 0.8,
                  alpha = 0.8,
                  color = "red") +
        labs(title = "Minority VAP share") +
        theme_bw()

    draws <- sample(levels(subset_sampled(plans)$draw), 3)
    p_ex1 <- redist.plot.plans(plans, draws[1], map)
    p_ex2 <- redist.plot.plans(plans, draws[2], map)
    p_ex3 <- redist.plot.plans(plans, draws[3], map)

    layout <- "
AAABBB
CCCDDD
EEEEEE
NNNNNN
FFFGGG
LLLMMM
HHHHHH
IIJJKK
IIJJKK"
    p <- patchwork::wrap_plots(A = p_wgts, B = p_div, C = p_dev, D = p_comp1,
                               E = p_comp2, `F` = p_split1, G = p_split2,
                               H = p_vra, I = p_ex1, J = p_ex2, K = p_ex3,
                               L = p_split3, M = p_split4, N = p_comp3,
                               design = layout) +
        patchwork::plot_annotation(title = str_c(map$state[1], " Validation")) +
        patchwork::plot_layout(guides = "collect")
    out_path <- here(str_glue("data-raw/{map$state[1]}/validation_{format(Sys.time(), '%Y%m%d_%H%M')}.png"))
    ggsave(out_path, plot = p, height = 18, width = 10)
    if (rstudioapi::isAvailable()) rstudioapi::viewer(out_path)
    invisible(out_path)
}
