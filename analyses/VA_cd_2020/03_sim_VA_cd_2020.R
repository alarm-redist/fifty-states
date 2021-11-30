###############################################################################
# Simulate plans for `VA_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg VA_cd_2020}")

plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county,
    verbose = TRUE)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/VA_2020/VA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg VA_cd_2020}")

plans <- add_summary_stats(plans, map)
plans_county <- add_summary_stats(plans_county, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/VA_2020/VA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
}
