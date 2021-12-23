###############################################################################
# Simulate plans for `NC_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_splits(1)

plans <- redist_smc(map, nsims = 5e3,
                    counties = pseudo_county,
                    constraints = constr)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NC_2020/NC_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NC_2020/NC_cd_2020_stats.csv")

cli_process_done()
