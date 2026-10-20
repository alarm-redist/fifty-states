###############################################################################
# Simulate plans for `CT_shd_2020` SHD
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CT_shd_2020}")

set.seed(2020)

constr <- redist_constr(map_shd) %>%
    add_constr_total_plan_splits(2, map_shd$county) |>
    add_constr_total_plan_splits(1, map_shd$county_muni)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 135


plans <- redist_smc(
    map_shd,
    nsims = 12e3, runs = 5,
    control = list(max_split_tries = 1000000),
    sampling_space = "spanning_forest",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    constraints = constr,
    ncores = 0
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "SHD_BEF")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/CT_2020/CT_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CT_shd_2020}")


plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CT_2020/CT_shd_2020_stats.csv")

cli_process_done()


if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)

}
