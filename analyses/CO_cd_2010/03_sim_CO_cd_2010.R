###############################################################################
# Simulate plans for `CO_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CO_cd_2010}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(2010)
plans <- redist_smc(map, nsims = 5e3, counties = county)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/CO_2010/CO_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CO_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CO_2010/CO_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
