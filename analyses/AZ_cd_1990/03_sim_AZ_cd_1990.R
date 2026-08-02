###############################################################################
# Simulate plans for `AZ_cd_1990`
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_1990}")

set.seed(1990)

constr_seed <- redist_constr(map) %>%
    add_constr_splits(strength = 0.25, admin = county_muni) %>%
    add_constr_grp_hinge(120, vap_hisp, vap, 0.50, only_districts = TRUE)

plans_seed <- redist_smc(map, nsims = 30000, counties = pseudo_county,
    constraints = constr_seed, n_steps = 1)

init_m <- get_plans_matrix(plans_seed)
init_m <- init_m[, sample(ncol(init_m), 4000), drop = FALSE]

constr_az <- redist_constr(map) %>%
    add_constr_splits(strength = 0.10, admin = county_muni) %>%
    add_constr_grp_hinge(30, vap_hisp, vap, 0.45, only_districts = TRUE) %>%
    add_constr_grp_hinge(-30, vap_hisp, vap, 0.20, only_districts = TRUE)

set.seed(1990)
plans <- redist_smc(map, nsims = 4000, runs = 5, counties = pseudo_county,
    constraints = constr_az, init_particles = init_m)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
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

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  validate_analysis(plans, map)
  summary(plans)
  
  plans_sampled <- subset_sampled(plans)
  
  # Hispanic VAP plot -----
  p_hvap <- redist.plot.distr_qtys(
    plans,
    vap_hisp / total_vap,
    color_thresh = NULL,
    color = ifelse(
      plans_sampled$ndv > plans_sampled$nrv,
      "#3D77BB",
      "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous(
      name = "Percent Hispanic by VAP",
      labels = scales::percent_format(accuracy = 1)
    ) +
    labs(
      title = "Arizona 1990 Enacted Plan versus Simulations",
      x = "Districts, ordered by Hispanic VAP"
    ) +
    scale_color_manual(
      values = c(cd_1990 = "black")
    ) +
    theme_bw()
  
  print(p_hvap)
  
  # Share of plans containing a district above each HVAP threshold -----
  plan_hvap <- plans_sampled |>
    as_tibble() |>
    mutate(
      hvap = vap_hisp / total_vap
    ) |>
    group_by(chain, draw) |>
    summarise(
      max_hvap = max(hvap, na.rm = TRUE),
      .groups = "drop"
    )
  
  if (nrow(plan_hvap) != 5000L) {
    warning(
      "Expected 5,000 simulated plans, but found ",
      nrow(plan_hvap),
      "."
    )
  }
  
  hvap_thresholds <- tibble(
    threshold = c(0.20, 0.30),
    label = factor(
      c("HVAP ≥ 20%", "HVAP ≥ 30%"),
      levels = c("HVAP ≥ 20%", "HVAP ≥ 30%")
    )
  ) |>
    rowwise() |>
    mutate(
      n_plans = sum(
        plan_hvap$max_hvap >= threshold,
        na.rm = TRUE
      ),
      total_plans = nrow(plan_hvap),
      proportion = n_plans / total_plans
    ) |>
    ungroup()
  
  print(hvap_thresholds)
  
  p_hvap_thresholds <- ggplot(
    hvap_thresholds,
    aes(x = label, y = proportion)
  ) +
    geom_col(width = 0.6) +
    geom_text(
      aes(
        label = paste0(
          scales::percent(proportion, accuracy = 0.1),
          "\n(",
          scales::comma(n_plans),
          " of ",
          scales::comma(total_plans),
          ")"
        )
      ),
      vjust = -0.3,
      size = 4
    ) +
    scale_y_continuous(
      name = "Share of simulated plans",
      labels = scales::percent_format(accuracy = 1),
      breaks = seq(0, 1, by = 0.2)
    ) +
    coord_cartesian(
      ylim = c(0, 1.05),
      clip = "off"
    ) +
    labs(
      title = paste0(
        "Arizona 1990: Plans Containing a District ",
        "Above Each Hispanic-VAP Threshold"
      ),
      x = NULL
    ) +
    theme_bw()
  
  print(p_hvap_thresholds)
}
