###############################################################################
# Simulate plans for `IL_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IL_cd_2010}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(20, vap_black, vap, tgts_group = 0.55) %>%
    add_constr_grp_hinge(-20, vap_black, vap, tgts_group = 0.45) %>%
    add_constr_grp_inv_hinge(10, vap_black, vap, tgts_group = 0.60) %>%
    add_constr_grp_hinge(20, vap_hisp, vap, tgts_group = 0.55) %>%
    add_constr_grp_hinge(-20, vap_hisp, vap, tgts_group = 0.44)

set.seed(2010)
plans <- redist_smc(map, nsims = 3e4, runs = 2L, counties = pseudo_county)#,
                    #pop_temper = 0.01) #%>%
    #group_by(chain) %>%
    #filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    #ungroup()
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IL_2010/IL_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IL_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IL_2010/IL_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)

    redist.plot.distr_qtys(plans, vap_black/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2010_prop = "black")) +
        ggredist::theme_r21()
    ggsave("figs/performance.pdf", height = 7, width = 7)

}
