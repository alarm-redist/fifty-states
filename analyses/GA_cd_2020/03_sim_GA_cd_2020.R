###############################################################################
# Simulate plans for `GA_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg GA_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(20, vap_black, vap, 0.52) %>%
    add_constr_grp_hinge(-20, vap_black, vap, 0.45) %>%
    add_constr_grp_inv_hinge(10, vap_black, vap, 0.62)
    # add_constr_grp_hinge(20, vap_black, vap, tgts_group = 0.55)
    # add_constr_grp_hinge(5, vap_black, vap, tgts_group = 0.55)

set.seed(2020)
plans <- redist_smc(map, nsims = 1e4, runs = 2L, counties = county, constraints = constr,
                    pop_temper = 0.01, ncores = 8)
plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/GA_2020/GA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg GA_cd_2020}")

plans <- add_summary_stats(plans, map)

summary(plans)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/GA_2020/GA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)

    redist.plot.distr_qtys(plans, vap_black / total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                           size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by VAP') +
        labs(title = 'Approximate Performance') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()
    ggsave("figs/performance.pdf", height = 7, width = 7)
}
