###############################################################################
# Simulate plans for `RI_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg RI_cd_2010}")

set.seed(2010)

# Minimize the number of state senate district splits
plans <- redist_smc(map, nsims = 1250, runs = 4L, counties = ssd_2010)
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/RI_2010/RI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg RI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/RI_2010/RI_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plans %>%
        mutate(ssd_split = county_splits(map, map$ssd_2010)) %>%
        group_by(draw) %>%
        summarize(ssd_split = ssd_split[1]) %>%
        hist(ssd_split) +
        labs(title = "State Senate District Splits") +
        theme_bw() +
        theme(aspect.ratio = 3/4)
}
