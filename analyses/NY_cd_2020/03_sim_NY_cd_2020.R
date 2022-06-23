###############################################################################
# Simulate plans for `NY_cd_2020`
# © ALARM Project, November 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NY_cd_2020}")

set.seed(2020)

plans <- redist_smc(
    map,
    nsims = 2e4, runs = 2L,
    seq_alpha = 0.95, counties = pseudo_county, pop_temper = 0.001
)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NY_2020/NY_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NY_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NY_2020/NY_cd_2020_stats.csv")

cli_process_done()
