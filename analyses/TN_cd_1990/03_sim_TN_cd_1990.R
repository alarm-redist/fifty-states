###############################################################################
# Simulate plans for `TN_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TN_cd_1990}")

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),
  error = function(e) "linking_edge"
)

set.seed(1990)
plans <- redist_smc(
  map,
  nsims = 6e3,
  runs = 5,
  counties = pseudo_county,
  constraints = constr,
  sampling_space = sampling_space_val,
  ms_params = list(frequency = 1L, mh_accept_per_smc = 60),
  split_params = list(splitting_schedule = "any_valid_sizes")
)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TN_1990/TN_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TN_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TN_1990/TN_cd_1990_stats.csv")

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
    labs(title = "Tennessee Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_1990 = "black")) +
    theme_bw()
  
  # Total Black districts that are performing
  plans %>%
    subset_sampled() %>%
    group_by(draw) %>%
    summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
    count(n_black_perf)
}
