###############################################################################
# Simulate plans for `NC_cd_2010`
# © ALARM Project, April 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_2010}")

set.seed(2010)

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(8, vap - vap_white, vap, 0.52) %>%
    add_constr_grp_hinge(-8, vap - vap_white, vap, 0.35) %>%
    add_constr_grp_inv_hinge(8, vap - vap_white, vap, 0.62)

plans <- redist_smc(map, nsims = 12e3,
    runs = 2L,
    ncores = 2L,
    counties = county,
    constraints = constr,
    pop_temper = 0.05)

plans <- match_numbers(plans, "cd_2010")

plans <- plans %>%
    mutate(vap_minority = group_frac(map, vap - vap_white, vap)) %>%
    group_by(draw) %>%
    mutate(vap_minority = sum(vap_minority > 0.4)) %>%
    ungroup() %>%
    filter(vap_minority >= 2 | draw == "cd_2010") %>%
    group_by(chain) %>%
    slice(1:(2500*attr(map, "ndists"))) %>% # thin samples
    ungroup() %>%
    select(-vap_minority) # remove extra column before saving

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
