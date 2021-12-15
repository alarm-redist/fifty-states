###############################################################################
# Simulate plans for `MS_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_2020}")

cons <- redist_constr(map) %>%
    add_constr_grp_hinge(25, vap_black, vap, tgts_group = c(0.55, 0.1))

plans <- redist_smc(map, nsims = 5e3, counties = county, constraints = cons)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MS_2020/MS_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MS_2020/MS_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans, vap_black / total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C')) +
        theme_bw()

}
