###############################################################################
# Simulate plans for `MA_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MA_cd_2010}")

set.seed(2010)
plans <- redist_smc(map, nsims = 3500, runs = 2L, counties = county_muni) %>%
    match_numbers("cd_2010") %>% group_by(chain) %>%
    # thin samples
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>%
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MA_2010/MA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MA_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics.
save_summary_stats(plans, "data-out/MA_2010/MA_cd_2010_stats.csv")

cli_process_done()

