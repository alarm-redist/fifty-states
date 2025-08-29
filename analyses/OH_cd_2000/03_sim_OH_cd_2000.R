###############################################################################
# Simulate plans for `OH_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OH_cd_2000}")

constr <- redist_constr(map) %>%
  add_constr_grp_hinge(3,  vap_black, vap, 0.45) %>%  
  add_constr_grp_hinge(-2,  vap_black, vap, 0.35)

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),
  error = function(e) "linking_edge"
)

set.seed(2000)
plans <- redist_smc(
  map, 
  nsims = 500, 
  runs = 10, 
  counties = county, 
  constraints = constr,
  sampling_space = sampling_space_val,
  ms_params      = list(ms_frequency = 1L, ms_moves_multiplier = 160L),
  split_params   = list(splitting_schedule = "any_valid_sizes"),
  ncores = parallel::detectCores())

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 500) %>% 
  ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OH_2000/OH_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OH_cd_2000}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OH_2000/OH_cd_2000_stats.csv")

cli_process_done()
