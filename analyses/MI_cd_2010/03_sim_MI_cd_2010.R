###############################################################################
# Simulate plans for `MI_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MI_cd_2010}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(13, vap - vap_white, vap, 0.52) %>%
    add_constr_grp_hinge(-13, vap - vap_white, vap, 0.3) %>%
    add_constr_grp_inv_hinge(8, vap - vap_white, vap, 0.62)

set.seed(2010)
plans <- redist_smc(map, nsims = 8000, runs = 2, ncores = 1, counties = pseudo_county, constraints = constr)%>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MI_2010/MI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MI_2010/MI_cd_2010_stats.csv")

cli_process_done()

