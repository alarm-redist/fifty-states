###############################################################################
# Simulate plans for `AZ_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_compet(15, ndv, nrv) %>%
    add_constr_grp_hinge(10, vap_hisp, vap, 0.55) %>%
    add_constr_grp_hinge(-5, vap_hisp, vap, 0.28) %>%
    add_constr_grp_hinge(-10, vap_hisp, vap, 0.35) %>%
    add_constr_grp_inv_hinge(8, vap_hisp, vap, 0.6) %>%
    add_constr_grp_hinge(4, vap_hisp, vap, 0.15) %>%
    suppressWarnings()

set.seed(2020)

plans <- redist_smc(map, nsims = 15e3, runs = 4L, counties = pseudo_county,
    constraints = constr, pop_temper = 0.04, seq_alpha = 0.95) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1250) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_2020/AZ_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_2020/AZ_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plot(constr)

    # competitiveness
    constr <- redist_constr(map) %>%
        add_constr_grp_pow(1e3, vap_hisp, vap, 0.51, 0.15, pow = 1.4)

    plans_no <- redist_smc(map, nsims = 1e3, counties = pseudo_county) %>%
        add_summary_stats(map)

    p1 <- plot(plans, ndshare, geom = "boxplot") +
        geom_hline(yintercept = 0.5, lty = "dashed", color = "red") +
        scale_y_continuous("Democratic share", labels = scales::percent) +
        labs(title = "With competitiveness")
    p2 <- plot(plans_no, ndshare, geom = "boxplot") +
        geom_hline(yintercept = 0.5, lty = "dashed", color = "red") +
        scale_y_continuous("Democratic share", labels = scales::percent) +
        labs(title = "Without competitiveness")
    p1 + p2 + plot_layout(guides = "collect")

    # VRA
    plans %>%
        mutate(min = vap_hisp/total_vap) %>%
        number_by(min) %>%
        redist.plot.distr_qtys(ndshare, sort = "none", geom = "boxplot") +
        labs(x = "Districts, ordered by HVAP", y = "Average Democratic share")

    redist.plot.distr_qtys(plans, vap_hisp / total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                           size = 0.1) +
        scale_y_continuous('Percent Hispanic by VAP') +
        labs(title = 'Approximate Performance') +
        scale_color_manual(values = c(cd_2020_prop = 'black'))

}
