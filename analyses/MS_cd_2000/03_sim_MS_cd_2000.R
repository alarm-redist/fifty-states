###############################################################################
# Simulate plans for `MS_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_2000}")

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_grp_hinge(20, vap_black, vap, 0.55) %>%
    add_constr_grp_hinge(-15, vap_black, vap, 0.3) %>%
    add_constr_grp_hinge(-15, vap_black, vap, 0.25)

set.seed(2000)
plans <- redist_smc(map, nsims = 2500, runs = 20, counties = county, constraints = constr_sc)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MS_2000/MS_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MS_2000/MS_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Dem seats by bvap rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
      subset_sampled() %>%
      select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(bvap_rank) %>%
      summarize(dem = mean(dem))

    # VRA
    plans %>%
      mutate(min = vap_black/total_vap) %>%
      number_by(min) %>%
      redist.plot.distr_qtys(ndshare, sort = "none", geom = "boxplot") +
      labs(x = "Districts, ordered by bvap", y = "Average Democratic share")

    plans_ranked <- plans %>%
      mutate(bvap = vap_black / total_vap) %>%
      number_by(bvap)

    redist.plot.distr_qtys(plans_ranked, ndshare, sort = "none", geom = "boxplot") +
      labs(x = "Districts, ordered by bvap", y = "Average Democratic share")

    redist.plot.distr_qtys(plans, vap_black/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.1) +
      scale_y_continuous("Percent black by VAP") +
      labs(title = "Approximate Performance") +
      scale_color_manual(values = c(cd_2000 = "black"))
}
