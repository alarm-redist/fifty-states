###############################################################################
# Simulate plans for `NY_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NY_cd_1990}")

sampling_space_val <- tryCatch(getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge")

set.seed(1990)
plans <- redist_smc(
    map,
    nsims = 1200, runs = 5,
    counties = pseudo_county,
    pop_temper = 0.01, seq_alpha  = 0.90,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 80),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    ncores = max(1, parallel::detectCores() - 1)
)
attr(plans, "existing_col") <- "cd_1990"

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NY_1990/NY_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NY_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NY_1990/NY_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
