###############################################################################
# Simulate plans for `CO_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CO_cd_2020}")

# TODO any pre-computation (VRA targets, etc.)
cons <- list(party = list(strength = 10, rvote = map$nrv, dvote = map$ndv, tgts_party = 0.50))
# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
plans <- redist_smc(map, nsims = 5e3, counties = county_muni)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_plans object. Do not edit this path.
write_rds(plans, here("data-out/CO_2020/CO_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CO_cd_2020}")
plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CO_2020/CO_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
