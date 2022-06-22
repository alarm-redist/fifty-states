###############################################################################
# Simulate plans for `LA_cd_2020`
# © ALARM Project, March 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_2020}")

constr <- redist_constr(map_m) %>%
    add_constr_grp_hinge(25, vap - vap_white, vap, 0.55) %>%
    add_constr_grp_hinge(-25, vap - vap_white, vap, 0.46) %>%
    add_constr_grp_inv_hinge(10, vap - vap_white, vap, 0.6)

set.seed(2020)
plans <- redist_smc(map_m, nsims = 8e3,
    runs = 2L,
    counties = pseudo_county,
    constraints = constr) %>%
    pullback(map) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()
attr(plans, "prec_pop") <- map$pop

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/LA_2020/LA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_2020/LA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Minority Percentage by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

}
