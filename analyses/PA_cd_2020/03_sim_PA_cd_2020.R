###############################################################################
# Simulate plans for `PA_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg PA_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_splits(0.25, coalesce(map$county_muni, "<bg>"))

set.seed(2020)

plans <- redist_smc(map, nsims = 5000, runs = 2L, counties = pseudo_county,
    constraints = constr, pop_temper = 0.02, verbose = TRUE) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, map$cd_2020)


cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/PA_2020/PA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg PA_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/PA_2020/PA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)

    # check performance
    redist.plot.distr_qtys(plans, 1 - vap_white/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.1) +
        scale_y_continuous("Percent Minority by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020 = "black"))
}
