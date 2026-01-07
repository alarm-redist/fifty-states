###############################################################################
# Simulate plans for `WV_cd_1990`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WV_cd_1990}")

set.seed(1990)
plans <- redist_smc(map, nsims = 2e3, runs = 5, counties = county)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WV_1990/WV_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WV_cd_1990}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WV_1990/WV_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)

  # Standard ALARM validation plots
  validate_analysis(plans, map)
  summary(plans)

  # Custom compactness validation plots
  plans_sum <- plans %>%
    group_by(draw) %>%
    summarize(comp_lw = sum(comp_lw),
              comp_perim = sum(comp_perim))
  p_lw <- hist(plans_sum, comp_lw, bins = 40) + labs(title = "Length-width compactness") + theme_bw()
  p_perim <- hist(plans_sum, comp_perim, bins = 40) + labs(title = "Perimeter compactness") + theme_bw()
  p <- p_lw + p_perim + plot_layout(guides = "collect")
  ggsave("data-raw/NV/validation_comp.png", width = 10, height = 5)
}
