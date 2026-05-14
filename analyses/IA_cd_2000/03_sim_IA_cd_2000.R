###############################################################################
# Simulate plans for `IA_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IA_cd_2000}")

set.seed(2000)
plans <- redist_smc(
    map, nsims = 5000, runs = 10,
    sampling_space = "linking_edge",
    pop_temper = 0.01, seq_alpha = 1,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 40),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    ncores = 112
)

plans <- plans %>% filter(draw != "cd_2000") %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 500) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IA_2000/IA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IA_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IA_2000/IA_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
