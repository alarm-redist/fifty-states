###############################################################################
# Simulate plans for `KS_cd_2020`
# © ALARM Project, January 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg KS_cd_2020}")

merge_idx <- attr(map_m, "merge_idx")
constr <- redist_constr(map_m) %>%
    add_constr_custom(1.0, function(plan, i) {
        sum(tapply(map$county, plan[merge_idx] == i, n_distinct) - 1L)
    })

plans <- redist_smc(map_m, nsims = 5e3,
    counties = county,
    constraints = constr) %>%
    pullback(map)
attr(plans, "prec_pop") <- map$pop

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
