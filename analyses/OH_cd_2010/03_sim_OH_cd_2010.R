###############################################################################
# Simulate plans for `OH_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OH_cd_2010}")

set.seed(2010)
plans <- redist_smc(map, nsims = 6500, runs = 2L, counties = pseudo_county) %>%
    pullback(map) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OH_2010/OH_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OH_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OH_2010/OH_cd_2010_stats.csv")

cli_process_done()
