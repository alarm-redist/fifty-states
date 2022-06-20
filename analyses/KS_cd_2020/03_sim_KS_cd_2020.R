###############################################################################
# Simulate plans for `KS_cd_2020`
# © ALARM Project, January 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg KS_cd_2020}")

set.seed(2020)
plans <- redist_smc(map_m, nsims = 2.5e3,
    runs = 2L, counties = county, seq_alpha = 0.7,
    constraints = constr) %>%
    pullback(map)
attr(plans, "prec_pop") <- map$pop

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/KS_2020/KS_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg KS_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/KS_2020/KS_cd_2020_stats.csv")

cli_process_done()
