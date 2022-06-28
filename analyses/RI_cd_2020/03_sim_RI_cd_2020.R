###############################################################################
# Simulate plans for `RI_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg RI_cd_2020}")

cons <- redist_constr(map) %>%
    add_constr_grp_hinge(
        strength = 2,
        group_pop = vap - vap_white,
        total_pop = vap
    )

set.seed(2020)
plans <- redist_smc(map, nsims = 2.5e3,
    runs = 2L,
    counties = sd_2020,
    constraints = cons)
plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/RI_2020/RI_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg RI_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/RI_2020/RI_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plans %>%
        mutate(sd_split = county_splits(map, map$sd_2020)) %>%
        group_by(draw) %>%
        summarize(sd_split = sd_split[1]) %>%
        hist(sd_split) +
        labs(title = "Senate district splits") +
        theme_bw() +
        theme(aspect.ratio = 3/4)
}
