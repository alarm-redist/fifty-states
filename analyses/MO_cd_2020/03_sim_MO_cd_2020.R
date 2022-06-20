###############################################################################
# Simulate plans for `MO_cd_2020`
# © ALARM Project, January 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MO_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(6, vap_black, vap, 0.4) %>%
    add_constr_grp_hinge(-3, vap_black, vap, 0.25) %>%
    add_constr_grp_hinge(-3, vap_black, vap, 0.08)

set.seed(2020)

plans <- redist_smc(map, nsims = 5e3, runs = 2L, ncores = 8, seq_alpha = 0.95,
    counties = county, constraints = constr) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MO_2020/MO_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MO_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MO_2020/MO_cd_2020_stats.csv")

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
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        ggredist::theme_r21()
}
