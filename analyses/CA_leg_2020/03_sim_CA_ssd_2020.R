###############################################################################
# Simulate plans for `CA_ssd_2020` SSD
# © ALARM Project, June 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 50

plans <- redist_smc(
    map_ssd,
    nsims = 3000, runs = 5,
    constraints = constr_ssd,
    ncores = 0,
    counties = pseudo_county,
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
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/CA_2020/CA_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# The following line is uncommented when viewing validation plots
# plans <- readRDS("data-out/CA_2020/CA_ssd_2020_plans.rds")

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CA_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CA_2020/CA_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
    summary(plans)

    # Extra validation plots for custom constraints -----

    visual <- redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hisp by VAP") +
        labs(title = "Approximate Performance")
    plans |>
        subset_sampled() |>
        group_by(draw) |>
        summarize(n_hisp_perf = sum(vap_hisp/total_vap > 0.3 & ndshare > 0.5)) |>
        count(n_hisp_perf)

    print(visual)
}
