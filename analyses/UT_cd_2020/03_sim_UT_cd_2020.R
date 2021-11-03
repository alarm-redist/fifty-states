###############################################################################
# Simulate plans for `UT_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg UT_cd_2020}")

plans <- redist_smc(map, nsims = 5e3,
                    counties = pseudo_county)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/UT_2020/UT_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg UT_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/UT_2020/UT_cd_2020_stats.csv")

cli_process_done()

# Validation analyses of simulations
validate_analysis(plans, map)

# Validation plot for Democrat share
if (interactive()) {
    library(ggplot2)
    library(patchwork)
    plans %>%
        mutate(dvs_20 = group_frac(map, adv_20, adv_20 + arv_20)) %>%
        redist.plot.distr_qtys(qty = dvs_20, geom = "boxplot") +
            theme_bw() +
            lims(y = c(0,1)) +
            labs(title = 'Democrat Share', y = "dem 2020")
    ggsave('data-raw/UT/dem_share.png')
}

