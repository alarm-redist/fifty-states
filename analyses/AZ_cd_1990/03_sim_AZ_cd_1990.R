###############################################################################
# Simulate plans for `AZ_cd_1990`
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_1990}")

set.seed(1990)

constr_az <- redist_constr(map) %>%
  add_constr_splits(
    strength = 0.25,
    admin = county_muni
  ) %>%
  add_constr_grp_hinge(
    20,
    vap_hisp,
    vap,
    0.32
  ) %>%
  add_constr_grp_hinge(
    -20,
    vap_hisp,
    vap,
    0.27
  )

plans <- redist_smc(
  map,
  nsims = 4000,
  runs = 5,
  counties = pseudo_county,
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

write_rds(
  plans,
  here("data-out/AZ_1990/AZ_cd_1990_plans.rds"),
  compress = "xz"
)

cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_1990}")

plans <- add_summary_stats(plans, map)

save_summary_stats(
  plans,
  "data-out/AZ_1990/AZ_cd_1990_stats.csv"
)

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
  
  perf_summary <- perf |>
    group_by(threshold) |>
    summarize(
      plans_with_any = sum(n[n_hisp_perf > 0]),
      pct_with_any = plans_with_any / sum(n),
      plans_with_two_or_more = sum(n[n_hisp_perf >= 2]),
      .groups = "drop"
    ) |>
    mutate(
      pct_with_any = scales::percent(
        pct_with_any,
        accuracy = 0.01
      )
    )
  
  print(perf_summary)
}
