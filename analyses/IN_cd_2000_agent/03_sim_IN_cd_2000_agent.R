###############################################################################
# Simulate plans for `IN_cd_2000_agent`
# © ALARM Project, April 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IN_cd_2000_agent}")

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 5, counties = pseudo_county, ncores = 15)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_plans object. Do not edit this path.
write_rds(plans, here("data-out/IN_2000_agent/IN_cd_2000_agent_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IN_cd_2000_agent}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IN_2000_agent/IN_cd_2000_agent_stats.csv")

cli_process_done()

# Extra validation plots -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
