###############################################################################
# Simulate plans for `OK_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OK_cd_2010}")

set.seed(2010)
plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county, runs = 2)

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")



# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OK_2010/OK_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OK_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OK_2010/OK_cd_2010_stats.csv")

cli_process_done()
