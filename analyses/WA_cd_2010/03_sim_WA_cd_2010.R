###############################################################################
# Simulate plans for `WA_cd_2010`
# © ALARM Project, July 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WA_cd_2010}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(8.0, vap - vap_white, vap, c(0.52, 0.35, 0.25)) %>%
    add_constr_grp_hinge(-8.0, vap - vap_white, vap, c(0.35, 0.25))



set.seed(2010)
plans <- redist_smc(map, nsims = 7000, counties = pseudo_county, constraints = constr, runs = 2L) %>% match_numbers("cd_2010") %>% group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
  ungroup()

plans <- match_numbers(plans, map$cd_2010)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. 
write_rds(plans, here("data-out/WA_2010/WA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WA_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics.
save_summary_stats(plans, "data-out/WA_2010/WA_cd_2010_stats.csv")

cli_process_done()


