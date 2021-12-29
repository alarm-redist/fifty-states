###############################################################################
# Simulate plans for `GA_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg GA_cd_2020}")

# TODO any pre-computation (VRA targets, etc.)

ga_black_prop <- sum(ga_shp$vap_black) / sum(ga_shp$vap)

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(30, vap_black, vap, tgts_group = c(0.55, ga_black_prop))

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!

plans <- redist_smc(map, nsims = 5e3, counties = county)
plans_vra <- redist_smc(map, nsims = 5e3, counties = county,
                        constraints = constr)

# plans_vra_100 <- redist_smc(map, nsims = 5e3, counties = county,
#                             constraints = list(vra = list(strength = 100,
#                                                           tgt_vra_min = 0.55,
#                                                           tgt_vra_other = ga_prop)))

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/GA_2020/GA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg GA_cd_2020}")

plans <- add_summary_stats(plans, map)
plans_vra <- add_summary_stats(plans_vra, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/GA_2020/GA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans_vra, map)
}
