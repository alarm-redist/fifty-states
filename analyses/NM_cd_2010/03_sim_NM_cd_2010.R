###############################################################################
# Simulate plans for `NM_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NM_cd_2010}")

constr <- redist_constr(map_cores) %>%
    add_constr_grp_hinge(25, vap - vap_white, vap, 0.52) %>%
    add_constr_grp_hinge(-25, vap - vap_white, vap, 0.47) %>%
    add_constr_grp_inv_hinge(20, vap - vap_white, vap, 0.57)

set.seed(2010)
plans <- redist_smc(map_cores,
                    nsims = 2500,
                    runs = 2L,
                    counties = county,
                    constr = constr) %>%
    pullback(map)
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NM_2010/NM_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NM_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NM_2010/NM_cd_2010_stats.csv")

cli_process_done()
