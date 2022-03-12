###############################################################################
# Simulate plans for `LA_cd_2020`
# © ALARM Project, March 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_2020}")

constr <- redist_constr(map_m) %>%
    add_constr_grp_hinge(40, vap_black, vap, tgts_group = 0.55)

plans <- redist_smc(map_m, nsims = 6e3,
    counties = pseudo_county, constraints = constr) %>%
    pullback(map)
attr(plans, "prec_pop") <- map$pop

plans <- plans %>%
    mutate(vap_minority = group_frac(map, vap - vap_white, vap)) %>%
    group_by(draw) %>%
    mutate(vap_minority = sum(vap_minority > 0.5)) %>%
    ungroup() %>%
    filter(vap_minority >= 1 | draw == "cd_2010") %>%
    slice(1:(5001*attr(map, "ndists"))) %>%
    select(-vap_minority)

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

    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        ggredist::theme_r21()

}
