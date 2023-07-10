###############################################################################
# Simulate plans for `HI_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_2010}")

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

plans <- plans %>%
    mutate(chain = rep(1:2, each = 5000), .after = draw) %>%
    add_reference(ref_plan = map$cd_2010, "cd_2010") %>%
    match_numbers("cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/HI_2010/HI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_2010/HI_cd_2010_stats.csv")

cli_process_done()
