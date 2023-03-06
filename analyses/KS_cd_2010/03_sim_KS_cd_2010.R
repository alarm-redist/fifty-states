###############################################################################
# Simulate plans for `KS_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg KS_cd_2010}")

set.seed(2010)
plans <- redist_smc(map_m, nsims = 1250, ncores = 4,
    runs = 4L, counties = county, seq_alpha = 0.7) %>%
    pullback(map)

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/KS_2010/KS_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg KS_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/KS_2010/KS_cd_2010_stats.csv")

cli_process_done()
