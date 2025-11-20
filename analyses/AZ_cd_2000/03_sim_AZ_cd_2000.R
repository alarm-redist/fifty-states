###############################################################################
# Simulate plans for `AZ_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_2000}")

constr_az <- redist_constr(map) %>%
    add_constr_splits(strength = 1, admin = county_muni) %>%
    add_constr_grp_hinge(10, vap_hisp, vap, 0.5) %>%
    add_constr_grp_hinge(-10, vap_hisp, vap, 0.28)

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 10, counties = county, pop_temper = 0.03, constraints = constr_az, seq_alpha = 0.99)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_2000/AZ_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_2000/AZ_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Dem seats by HVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(hvap = vap_hisp/total_vap, hvap_rank = rank(hvap)) %>%
        subset_sampled() %>%
        select(draw, district, hvap, hvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(hvap_rank) %>%
        summarize(dem = mean(dem))

    # VRA
    plans %>%
        mutate(min = vap_hisp/total_vap) %>%
        number_by(min) %>%
        redist.plot.distr_qtys(ndshare, sort = "none", geom = "boxplot") +
        labs(x = "Districts, ordered by HVAP", y = "Average Democratic share")

    plans_ranked <- plans %>%
      mutate(hvap = vap_hisp / total_vap) %>%
      number_by(hvap)

    redist.plot.distr_qtys(plans_ranked, ndshare, sort = "none", geom = "boxplot") +
      labs(x = "Districts, ordered by HVAP", y = "Average Democratic share")

    redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.1) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2000 = "black"))
}
