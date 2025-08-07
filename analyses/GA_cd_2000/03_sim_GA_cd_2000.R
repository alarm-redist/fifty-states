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
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/GA_2000/GA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg GA_cd_2000}")

plans <- add_summary_stats(plans, map)

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
