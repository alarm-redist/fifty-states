###############################################################################
# Simulate plans for `AR_shd_2020` SHD
# © ALARM Project, June 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AR_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 50

constr <- redist_constr(map_shd) |>
    add_constr_status_quo(strength = 500, current = map_shd$shd_2010)

plans <- redist_smc(
    map_shd,
    nsims = 2e3, runs = 5,
    counties = map_shd$pseudo_county,
    constraints = constr,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    ncores = 64 # ran on FASCR cluster on a serial_requeue partition
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
write_rds(plans, here("data-out/AR_2020/AR_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AR_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AR_2020/AR_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)

    # Extra validation plots for custom constraints -----

    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020_prop = "black"))

    plans_nocores <- redist_smc(
        map_shd,
        nsims = 200,
        runs = 2,
        counties = map_shd$pseudo_county
    )

    d_overl <- bind_rows(
        with_cores = as_tibble(match_numbers(plans, map_shd$shd_2010)),
        no_cores = as_tibble(match_numbers(plans_nocores, map_shd$shd_2010)),
        .id = "run"
    )

    ggplot(d_overl |> distinct(run, draw, pop_overlap),
        aes(x = pop_overlap, color = run, fill = run)) +
        geom_density(alpha = 0.3)

    p_core <- plans |>
        match_numbers(map_shd$shd_2010) |>
        hist(pop_overlap)
    print(p_core)
}
