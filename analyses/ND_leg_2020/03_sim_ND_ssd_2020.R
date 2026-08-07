###############################################################################
# Simulate plans for `ND_ssd_2020` SSD
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ND_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd_cores$ssd_2020)/3) + 120

constr <- redist_constr(map_ssd_cores) |>
    add_constr_total_splits(strength = 1.2, admin = county) |>
    add_constr_total_splits(strength = 0.3, admin = muni) |>
    add_constr_polsby(strength = 1.5)

plans_full <- redist_smc(
    map_ssd_cores,
    nsims = 5000, runs = 5,
    counties = pseudo_county,
    constraints = constr,
    ncores = 0,
    pop_temper = 0.04,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
) |> pullback(map_ssd)

plans <- plans_full |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")
plans_full <- match_numbers(plans_full, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_full, here("data-out/ND_2020/ND_ssd_2020_plans5000.rds"), compress = "xz")
write_rds(plans, here("data-out/ND_2020/ND_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ND_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/ND_2020/ND_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
    summary(plans)
}
