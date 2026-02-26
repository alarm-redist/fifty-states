###############################################################################
# Simulate plans for `WA_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WA_cd_1990}")

set.seed(1990)
plans <- redist_smc(map, nsims = 10000, counties = pseudo_county, runs = 5) %>%
  match_numbers("cd_1990") %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()

plans <- match_numbers(plans, map$cd_1990)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object.
write_rds(plans, here("data-out/WA_1990/WA_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WA_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics.
save_summary_stats(plans, "data-out/WA_1990/WA_cd_1990_stats.csv")

cli_process_done()
