###############################################################################
# Simulate plans for `MS_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_2010}")

cons <- redist_constr(map) %>%
    add_constr_grp_hinge(20, vap_black, vap, tgts_group = c(0.55)) %>%
    add_constr_grp_hinge(-20, vap_black, vap, tgts_group = 0.4) %>%
    add_constr_grp_hinge(-5, vap_black, vap, tgts_group = 0.2)

set.seed(2010)
plans <- redist_smc(
    map,
    nsims = 2500, runs = 2L,
    counties = county,
    constraints = cons
)

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MS_2010/MS_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MS_2010/MS_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Mississippi Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black")) +
        theme_bw()

}
