###############################################################################
# Simulate plans for `NV_cd_1990`
# © ALARM Project, January 2026
###############################################################################
# Run the simulation -----
cli_process_start("Running simulations for {.pkg NV_cd_1990}")
set.seed(1990)
plans <- redist_smc(map, nsims = 4000, runs = 4,
                    compactness = 1.1, seq_alpha = 0.9)
plans <- match_numbers(plans, map$cd_1990)

# thin out the runs
plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1250) %>% # thin samples
  ungroup()
cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NV_1990/NV_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NV_cd_1990}")
plans <- add_summary_stats(plans, map)
save_summary_stats(plans, "data-out/NV_1990/NV_cd_1990_stats.csv")
cli_process_done()

# Extra validation plots -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  # Standard ALARM validation plots
  validate_analysis(plans, map)
  summary(plans)
}
