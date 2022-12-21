###############################################################################
# Simulate plans for `HI_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_2010}")

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

plans_honolulu <- redist_smc(
    map_honolulu,
    nsims = 2500, runs = 2L,
    n_steps = 1,
    counties = coalesce(muni, county)
)

plans <- matrix(data = 0, nrow = nrow(map), ncol = 5001)
plans[map$tract %in% map_honolulu$tract, ] <- get_plans_matrix(plans_honolulu)
plans[plans == 0] <- 2

plans <- redist_plans(
    plans = plans[, -1],
    algorithm = "smc",
    map = map,
    wgt = get_plans_weights(plans_honolulu)[-1],
    diagnostics = attr(plans_honolulu, "diagnostics")
)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

plans <- plans %>%
    mutate(chain = rep(1:2, each = 5000), .after = draw) %>%
    add_reference(ref_plan = map$cd_2010, "cd_2010")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/HI_2010/HI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_2010/HI_cd_2010_stats.csv")

cli_process_done()
