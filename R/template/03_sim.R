###############################################################################
# Simulate plans for ```SLUG```
# ``COPYRIGHT``
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ``SLUG``}")

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
plans = redist_smc(map, nsims = 5e3, counties = county_muni)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/``STATE``_``YEAR``/``SLUG``_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ``SLUG``}")

plans = add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/``STATE``_``YEAR``/``SLUG``_stats.csv")

cli_process_done()
