###############################################################################
# Simulate plans for `LA_cd_1990`
# © ALARM Project, February 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_1990}")

BVAP_THRESH <- 0.30
DEM_THRESH  <- 0.45
ndists <- attr(map, "ndists")

constr <- redist_constr(map) |>
    add_constr_grp_hinge(
        0.01,
        vap_black,
        vap,
        BVAP_THRESH
    ) |>
    add_constr_min_group_frac(
        strength      = -1,
        group_pops    = list(map$vap_black, map$ndv),
        total_pops    = list(map$vap, map$nrv + map$ndv),
        min_fracs     = c(BVAP_THRESH, DEM_THRESH),
        thresh        = -0.9,
        only_nregions = seq.int(2, ndists)
    ) |>
    add_constr_min_group_frac(
        strength      = -1,
        group_pops    = list(map$vap_black, map$ndv),
        total_pops    = list(map$vap, map$nrv + map$ndv),
        min_fracs     = c(BVAP_THRESH, DEM_THRESH),
        thresh        = -1.9,
        only_nregions = ndists
    )

set.seed(1990)
plans <- redist_smc(
    map,
    nsims = 1e3,
    runs = 5,
    counties = county,
    constraints = constr,
    split_params = list(splitting_schedule = "any_valid_sizes"),
    sampling_space = "spanning_forest",
    ms_params = list(frequency = 1L, mh_accept_per_smc = 80)
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/LA_1990/LA_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_1990/LA_cd_1990_stats.csv")

cli_process_done()

# Validation plots
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2000 = "black")) +
        theme_bw()

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)
}
