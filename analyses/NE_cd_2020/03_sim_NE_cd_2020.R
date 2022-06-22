###############################################################################
# Simulate plans for `NE_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NE_cd_2020}")

set.seed(2020)

plans <- redist_smc(map_cores, nsims = 1250, runs = 4L, counties = county) %>%
    pullback(map)

plans <- match_numbers(plans, map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NE_2020/NE_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NE_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NE_2020/NE_cd_2020_stats.csv")

cli_process_done()
