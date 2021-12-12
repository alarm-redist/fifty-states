###############################################################################
# Simulate plans for `MS_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_2020}")

cons <- redist_constr(map) %>%
    add_constr_grp_hinge(25, vap - vap_white, vap)

plans <- redist_smc(map, nsims = 5e3, counties = county, constraints = cons)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MS_2020/MS_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MS_2020/MS_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
