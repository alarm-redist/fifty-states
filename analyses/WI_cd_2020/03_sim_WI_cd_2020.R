###############################################################################
# Simulate plans for `WI_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WI_cd_2020}")

# TODO any pre-computation (VRA targets, etc.)

cons <- redist_constr(map) %>%
    add_constr_grp_hinge(
        strength = 100,
        group_pop = vap - vap_white,
        total_pop = vap
    )
plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county,
    constraints = cons)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WI_2020/WI_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WI_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WI_2020/WI_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Wisconsin Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black")) +
        ggredist::theme_r21()
}
