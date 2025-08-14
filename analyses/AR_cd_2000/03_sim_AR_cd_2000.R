###############################################################################
# Simulate plans for `AR_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AR_cd_2000}")

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 5, counties = county, constraints = constr)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AR_2000/AR_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AR_cd_2000}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AR_2000/AR_cd_2000_stats.csv")

cli_process_done()
