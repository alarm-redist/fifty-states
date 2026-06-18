###############################################################################
# Simulate plans for `NM_cd_2000`
# © ALARM Project, October 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NM_cd_2000}")
set.seed(2000)
plans <- redist_smc(map,
    nsims = 2000,
    runs = 10,
    counties = pseudo_county,
    sampling_space = "linking_edge",
    pop_temper = 0.05,
    seq_alpha  = 0.9,
    ms_params = list(
        frequency = 1,
        mh_accept_per_smc = 50,
        pair_rule = "uniform")
)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 500) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NM_2000/NM_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NM_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NM_2000/NM_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
