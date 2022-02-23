###############################################################################
# Simulate plans for `PA_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg PA_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_splits(0.2, coalesce(map$county_muni, "<bg>"))

plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county,
    constraints = constr)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/PA_2020/PA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg PA_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/PA_2020/PA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # check performance
    mutate(plans, mvap = 1 - vap_white/total_vap) %>%
        number_by(mvap) %>%
        plot(e_dvs, size = 0.01, sort = F, color_thresh=0.5) +
        scale_color_manual(values=c("red", "blue")) +
        labs(x="Districts, ordered by minority VAP share",
             y="ExpectedDemocratic vote share")
}
