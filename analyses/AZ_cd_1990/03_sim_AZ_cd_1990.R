###############################################################################
# Simulate plans for `AZ_cd_1990`
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_1990}")

set.seed(1990)

constr_az <- redist_constr(map) %>%
  add_constr_grp_hinge(
    25,
    vap_hisp,
    vap,
    0.32
  )

plans <- redist_smc(
  map,
  nsims = 8000,
  runs = 5,
  constraints = constr_az
)

plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) |>
  ungroup()

plans <- match_numbers(plans, "cd_1990")

cli_process_done()

# Save plans -----
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_1990/AZ_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_1990/AZ_cd_1990_stats.csv")

cli_process_done()

# Validation plots -----
if (interactive()) {
  library(ggplot2)
  
  validate_analysis(plans, map)
  summary(plans)
  
  sampled <- subset_sampled(plans)
  
  print(
    redist.plot.distr_qtys(
      plans,
      vap_hisp / total_vap,
      color_thresh = NULL,
      color = ifelse(
        sampled$ndshare > 0.5,
        "#3D77BB",
        "#B25D4C"
      ),
      size = 0.5,
      alpha = 0.5
    ) +
      scale_y_continuous("Hispanic share of VAP") +
      labs(title = "Hispanic Performance") +
      scale_color_manual(values = c(cd_1990 = "black"))
  )
}
