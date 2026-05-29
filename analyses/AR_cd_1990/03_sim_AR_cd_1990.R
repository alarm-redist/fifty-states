###############################################################################
# Simulate plans for `AR_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AR_cd_1990}")

set.seed(1990)
plans <- redist_smc(map, nsims = 2e3, runs = 5, counties = county, constraints = constr)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AR_1990/AR_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AR_cd_1990}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AR_1990/AR_cd_1990_stats.csv")

cli_process_done()

# validation plots
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  validate_analysis(plans, map)
  summary(plans)
}
