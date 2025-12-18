###############################################################################
# Simulate plans for `NH_cd_2000`
# © ALARM Project, November 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NH_cd_2000}")

# Run simulations
set.seed(2000)
plans <- redist_smc(
  map,
  nsims    = 2e3,
  runs     = 10,
  counties = county,
  sampling_space = "linking_edge",
  pop_temper = 0.05,
  seq_alpha = 0.9,
  ms_params = list(frequency = 1, mh_accept_per_smc = 50, pair_rule = "uniform")
  )

# Thin plans
plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 500) %>% 
  ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NH_2000/NH_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NH_cd_2000}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NH_2000/NH_cd_2000_stats.csv")

cli_process_done()
