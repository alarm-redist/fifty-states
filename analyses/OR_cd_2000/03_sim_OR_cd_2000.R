###############################################################################
# Simulate plans for `OR_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OR_cd_2000}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 10, counties = county)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OR_2000/OR_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OR_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OR_2000/OR_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
      scale_y_continuous("Percent Black by VAP") +
      labs(title = "Oregon Proposed Plan versus Simulations") +
      scale_color_manual(values = c(cd_2020_prop = "black")) +
      theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
      scale_y_continuous("Minority Percentage by VAP") +
      labs(title = "Oregon Proposed Plan versus Simulations") +
      scale_color_manual(values = c(cd_2020_prop = "black")) +
      theme_bw()

    # Dem seats by BVAP rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
      subset_sampled() %>%
      select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(bvap_rank) %>%
      summarize(dem = mean(dem))

    # Dem seats by Minority VAP rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(tmvap = (total_vap - vap_white)/total_vap, tmvap_rank = rank(tmvap)) %>%
      subset_sampled() %>%
      select(draw, district, tmvap, tmvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(tmvap_rank) %>%
      summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & e_dvs > 0.5)) %>%
      count(n_black_perf)

    # Total Minority districts that are performing
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_minority_perf = sum((total_vap - vap_white)/total_vap < 0.5 & e_dvs > 0.5)) %>%
      count(n_minority_perf)

    # democratic vote
    plans <- plans %>%
      mutate(Compactness = distr_compactness(map),
             `Population deviation` = plan_parity(map),
             `Democratic vote` = group_frac(map, ndv, (ndv + nrv)))
    plot(plans, `Democratic vote`, size = 0.5, color_thresh = 0.5) +
      scale_color_manual(values = c("black", "tomato2", "dodgerblue")) +
      labs(title = "Democratic vote share by district")

    # majority minority districts
    plans <- plans %>%
      mutate(majmin = if_else(total_vap/2 > vap_white, 1, 0))
    majminavgs <- avg_by_prec(plans, majmin, draws = NA)
    redist.plot.map(
      or_shp,
      adj = redist.adjacency(or_shp, plan),
      plan = NULL,
      fill = majminavgs,
      fill_label = "",
      zoom_to = NULL,
      title = ""
    )

    # majority black districts
    plans <- plans %>%
      mutate(bvappct = vap_black/total_vap)
    blackavgs <- avg_by_prec(plans, bvappct, draws = NA)
    redist.plot.map(
      or_shp,
      adj = redist.adjacency(or_shp, plan),
      plan = NULL,
      fill = blackavgs,
      fill_label = "",
      zoom_to = NULL,
      title = ""
    )

    # this section does not work
    plot(plans, (total_vap - vap_white)/total_vap, sort = FALSE, size = 0.5)

    pal <- scales::viridis_pal()(5)[-1]
    redist.plot.scatter(plans, pct_min, pct_dem,
                        color = pal[subset_sampled(plans)$district]) +
      scale_color_manual(values = "black")

    avg_by_prec(plans, x, draws = NA)
    show(plans)

    redist.plot.distr_qtys(
      plans,
      qty = total_vap,
      sort = "asc",
      geom = "jitter",
      color_thresh = NULL,
      size = 0.1,
      ref_label = total_vap
    )
}
