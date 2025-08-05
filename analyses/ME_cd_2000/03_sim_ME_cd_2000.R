###############################################################################
# Simulate plans for `ME_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ME_cd_2000}")

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 10, counties = county, compactness = 0.8)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 500) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/ME_2000/ME_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ME_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/ME_2000/ME_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
