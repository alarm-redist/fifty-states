###############################################################################
# Simulate plans for `NV_cd_2010`
# © ALARM Project, September 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NV_cd_2010}")

set.seed(2010)
plans <- redist_smc(map,
    nsims = 5e3,
    runs = 2L,
    counties = pseudo_county) %>%
    match_numbers("cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NV_2010/NV_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NV_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NV_2010/NV_cd_2010_stats.csv")

cli_process_done()
