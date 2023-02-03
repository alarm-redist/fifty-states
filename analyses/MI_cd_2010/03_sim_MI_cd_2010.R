###############################################################################
# Simulate plans for `MI_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MI_cd_2010}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(13, vap - vap_white, vap, 0.52) %>%
    add_constr_grp_hinge(-13, vap - vap_white, vap, 0.3) %>%
    add_constr_grp_inv_hinge(8, vap - vap_white, vap, 0.62)

#  - Ask for help!
set.seed(2010)
plans <- redist_smc(map, nsims = 8000, runs = 4, counties = pseudo_county, constraints = constr) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1250) %>% # thin samples
    ungroup()

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MI_2010/MI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MI_2010/MI_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
