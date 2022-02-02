###############################################################################
# Simulate plans for `NC_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_splits(1, admin = county) %>%
    add_constr_grp_hinge(5, vap_black, vap, tgts_group = c(0.52))

plans <- redist_smc(map, nsims = 5e3,
                    counties = pseudo_county,
                    constraints = constr)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NC_2020/NC_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NC_2020/NC_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans, vap_black / total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                           size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by VAP') +
        labs(title = 'North Carolina Proposed Plan versus Simulations') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()

}
