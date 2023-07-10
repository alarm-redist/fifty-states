###############################################################################
# Simulate plans for `NY_cd_2010`
# © ALARM Project, September 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NY_cd_2010}")

set.seed(2010)
plans <- redist_smc(map,
    nsims = 3e4,
    seq_alpha = .95,
    runs = 2L,
    counties = pseudo_county, verbose = TRUE,
    pop_temper = .001, ncores = 15) %>%
    match_numbers("cd_2010")

thinned_plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>%
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(thinned_plans, here("data-out/NY_2010/NY_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NY_cd_2010}")

plans <- add_summary_stats(plans, map)
thinned_plans <- add_summary_stats(thinned_plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(thinned_plans, "data-out/NY_2010/NY_cd_2010_stats.csv")

cli_process_done()
