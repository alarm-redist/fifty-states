###############################################################################
# Simulate plans for `NC_cd_2010`
# © ALARM Project, April 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_2010}")

set.seed(12345)
constr <- redist_constr(map) %>%
    add_constr_splits(1, admin = county) %>%
    add_constr_grp_hinge(6, vap_black, vap, tgts_group = c(0.5))

plans <- redist_smc(map, nsims = 5e3,
    counties = county,
    constraints = constr)

plans <- plans %>%
    mutate(vap_minority = group_frac(map, vap - vap_white, vap)) %>%
    group_by(draw) %>%
    mutate(vap_minority = sum(vap_minority > 0.5)) %>%
    ungroup() %>%
    filter(vap_minority >= 2 | draw == "cd_2010") %>%
    slice(1:(5001*attr(map, "ndists"))) %>%
    select(-vap_minority)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NC_2010/NC_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NC_2010/NC_cd_2010_stats.csv")

cli_process_done()
