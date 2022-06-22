###############################################################################
# Simulate plans for `KY_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg KY_cd_2020}")

set.seed(2020)
plans <- redist_smc(map, nsims = 4e3, runs = 2L, counties = pseudo_county,
                    ncores = 8) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/KY_2020/KY_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg KY_cd_2020}")

plans <- add_summary_stats(plans, map)

summary(plans)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/KY_2020/KY_cd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)
    validate_analysis(plans, map)
    redist.plot.distr_qtys(plans, qty = ndshare, geom = "boxplot") +
        scale_y_continuous("Democratic Voteshare", labels = scales::percent_format(accuracy = 1)) +
        theme_bw()
    ggsave("figs/partisan.pdf", height = 4, width = 8)
}
