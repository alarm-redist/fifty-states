###############################################################################
# Simulate plans for `WI_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WI_cd_2020}")

cons <- redist_constr(map) %>%
    add_constr_splits(
        strength = 0.5,
        admin = pseudo_county
    )

set.seed(2020)

plans <- redist_smc(
    map,
    nsims = 2500, runs = 2L, ncores = 8,
    counties = pseudo_county,
    constraints = cons
)

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

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
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Minority by VAP") +
        labs(title = "Wisconsin Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        ggredist::theme_r21()

    pl_renum <- plans %>%
        match_numbers(plan = map$cd_2010)

    hist(pl_renum, pop_overlap, bins = 30) +
        ggredist::theme_r21()
}
