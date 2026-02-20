###############################################################################
# Simulate plans for `OH_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OH_cd_1990}")

constr <- redist_constr(map) %>%
  add_constr_grp_hinge(3,  vap_black, vap, 0.45) %>%
  add_constr_grp_hinge(-2,  vap_black, vap, 0.35)

set.seed(1990)
plans <- redist_smc(
  map,
  nsims = 600,
  runs = 10,
  counties = county,
  constraints = constr,
  pop_temper = 0.01, seq_alpha = 0.90,
  sampling_space = "linking_edge",
  ms_params      = list(frequency = 1L, mh_accept_per_smc = 30),
  split_params   = list(splitting_schedule = "any_valid_sizes"))

attr(plans, "existing_col") <- "cd_1990"

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 500) %>%
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OH_1990/OH_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OH_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OH_1990/OH_cd_1990_stats.csv")

cli_process_done()

# Validation plots
if (interactive()) {
  library(ggplot2)
  library(patchwork)

  # Black VAP Performance Plot
  redist.plot.distr_qtys(plans, vap_black / total_vap,
                         color_thresh = NULL,
                         color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                         size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "Ohio Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    theme_bw()

  # Total Black districts that are performing
  plans %>%
    subset_sampled() %>%
    group_by(draw) %>%
    summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
    count(n_black_perf)
}
