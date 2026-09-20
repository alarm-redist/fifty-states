###############################################################################
# Simulate plans for `AK_ssd_2020` SSD
# © ALARM Project, February 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AK_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- 35

constr <- redist_constr(map_ssd) %>%
    add_constr_total_splits(strength = 2, admin = county) %>%
    add_constr_polsby(strength = 8)

plans <- redist_smc(
    map_ssd,
    nsims = 10*2e3, runs = 5,
    constraints = constr,
    counties = pseudo_county,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    ncores = 64
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!
plans <- match_numbers(plans, "ssd_2020")

write_rds(plans, here("data-raw/AK/AK_ssd_2020_plans_oversample.rds"), compress = "xz")

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AK_2020/AK_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AK_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AK_2020/AK_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
    summary(plans)

}
