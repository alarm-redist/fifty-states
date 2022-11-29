###############################################################################
# Simulate plans for `WI_cd_2010`
# © ALARM Project, November 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WI_cd_2010}")

set.seed(2010)
plans <- redist_smc(map, nsims = 5e3,
                    counties = pseudo_county,
                    runs = 2L, verbose = TRUE, ncores = 16) %>%
    match_numbers("cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WI_2010/WI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WI_2010/WI_cd_2010_stats.csv")

cli_process_done()
