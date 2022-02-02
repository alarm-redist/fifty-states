###############################################################################
# Simulate plans for `HI_cd_2020`
# © ALARM Project, January 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_2020}")

plans_honolulu <- redist_smc(map_honolulu, nsims = 5e3, n_steps = 1,
    counties = coalesce(muni, county))

plans <- matrix(data = 0, nrow = nrow(map), ncol = 5001)
plans[map$tract %in% map_honolulu$tract, ] <- get_plans_matrix(plans_honolulu)
plans[plans == 0] <- 2

plans <- redist_plans(
    plans = plans[, -1],
    algorithm = "smc",
    map = map,
    wgt = get_plans_weights(plans_honolulu)[-1]
)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

plans <- plans %>%
    add_reference(ref_plan = map$cd_2020, "cd_2020")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/HI_2020/HI_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_2020/HI_cd_2020_stats.csv")

cli_process_done()
