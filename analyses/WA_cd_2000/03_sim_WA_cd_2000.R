###############################################################################
# Simulate plans for `WA_cd_2000`
# © ALARM Project, February 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WA_cd_2000}")

set.seed(2000)
plans <- redist_smc(map, nsims = 10000, counties = pseudo_county, runs = 5) %>%
    match_numbers("cd_2000") %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, map$cd_2000)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_plans object.
write_rds(plans, here("data-out/WA_2000/WA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WA_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics.
save_summary_stats(plans, "data-out/WA_2000/WA_cd_2000_stats.csv")

cli_process_done()
