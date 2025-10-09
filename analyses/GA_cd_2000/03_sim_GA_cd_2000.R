###############################################################################
# Simulate plans for `GA_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg GA_cd_2000}")

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 10, counties = county)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg GA_cd_2000}")

plans <- add_summary_stats(plans, map)

cli_process_done()

# Rejection sampling for ≥ 2 minority opportunity districts -----
MIN_OPP      <- 2
BVAP_THRESH  <- 0.30
DEM_THRESH   <- 0.50

cli_process_start(glue::glue(
    "Rejection sampling: keeping draws with ≥ {MIN_OPP} Black opportunity districts ",
    "(BVAP>{BVAP_THRESH}, Dem share>{DEM_THRESH})"
))

opp_by_draw <- plans %>%
    subset_sampled() %>%
    mutate(bvap = vap_black/total_vap, dem_share = ndshare) %>%
    group_by(draw) %>%
    summarise(n_black_opp = sum(bvap > BVAP_THRESH & dem_share > DEM_THRESH), .groups = "drop")

keep_draws <- opp_by_draw %>%
    filter(n_black_opp >= MIN_OPP) %>%
    pull(draw) %>%
    unique()

n_before <- n_distinct(plans$draw)
plans <- plans %>% filter(draw %in% keep_draws)
n_after  <- n_distinct(plans$draw)

cli::cli_alert_info("{n_after} / {n_before} draws retained after rejection sampling.")
if (n_after == 0) {
    cli::cli_alert_danger("All draws rejected. Consider relaxing thresholds or adding a hinge constraint.")
}
cli_process_done()

cli_process_start("Saving {.cls redist_plans} object (post-filter)")

# Output the redist_map object. Do not edit this path.
+write_rds(plans, here("data-out/GA_2000/GA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/GA_2000/GA_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    redist.plot.distr_qtys(
        plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2000 = "black"))

    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)
}
