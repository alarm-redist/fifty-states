###############################################################################
# Simulate plans for `LA_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_2000}")

constr <- redist_constr(map) %>%
  add_constr_grp_hinge(30, vap - vap_white, vap, 0.50) %>%
  add_constr_grp_hinge(-25, vap - vap_white, vap, 0.41) %>%
  add_constr_grp_inv_hinge(10, vap - vap_white, vap, 0.55)

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
write_rds(plans, here("data-out/LA_2000/LA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_cd_2000}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_2000/LA_cd_2000_stats.csv")

cli_process_done()
