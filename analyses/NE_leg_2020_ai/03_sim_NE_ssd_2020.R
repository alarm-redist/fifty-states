###############################################################################
# Simulate plans for `NE_ssd_2020` Nebraska legislative districts
# <U+00A9> ALARM Project, April 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NE_ssd_2020}")

set.seed(2020)

# `redist_smc()` checks `parallel::detectCores()` before honoring `ncores`,
# and this desktop sandbox can report `NA`; normalize to a single core here.
if (is.na(parallel::detectCores())) {
    assignInNamespace(
        "detectCores",
        function(all.tests = FALSE, logical = TRUE) 1L,
        ns = "parallel"
    )
}

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3)
constr <- redist_constr(map_ssd) |>
    add_constr_status_quo(strength = 0.05, current = map_ssd$ssd_2010)

plans <- redist_smc(
    map_ssd,
    nsims = 2e3, runs = 5,
    ncores = 1,
    constraints = constr,
    counties = pseudo_county,
    compactness = 1,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NE_2020/NE_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NE_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NE_2020/NE_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
    summary(plans)
}
