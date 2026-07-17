###############################################################################
# Simulate plans for `WV_shd_2020` SHD
# © ALARM Project, May 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WV_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 130

# County split constraint -----
constr <- redist_constr(map_shd)
constr <- add_constr_total_splits(
    constr,
    strength = 1.5,
    admin = county
)

plans <- redist_smc(
    map_shd,
    nsims = 2e3, runs = 5, ncores = 15L,
    counties = pseudo_county,
    constraints = constr,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()

plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WV_2020/WV_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WV_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WV_2020/WV_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)
}
