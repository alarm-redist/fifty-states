###############################################################################
# Simulate plans for `NH_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NH_cd_2020}")

plans <- redist_smc(map, nsims = 5e3, counties = county)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

plans <- plans %>% add_reference(map$dem_prop, "dem_prop")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NH_2020/NH_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NH_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NH_2020/NH_cd_2020_stats.csv")

cli_process_done()
