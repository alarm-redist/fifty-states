###############################################################################
# Simulate plans for `NH_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NH_cd_2020}")

plans <- redist_smc(map, nsims = 7e3, counties = mcd)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

plans <- plans %>% add_reference(map$dem_prop, "dem_prop")
plans <- plans %>%
    mutate(
        mcd_splits = redistmetrics::splits_admin(., map, mcd)
    ) %>%
    filter(mcd_splits == 0) %>%
    slice(1:(5002 * 2))

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NH_2020/NH_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NH_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NH_2020/NH_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)
    library(redistmetrics)

    hist(plans %>% mutate(splits_mcd = splits_admin(., map, mcd)), splits_mcd) +
        theme_bw()
}
