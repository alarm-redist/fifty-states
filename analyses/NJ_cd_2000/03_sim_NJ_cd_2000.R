###############################################################################
# Simulate plans for `NJ_cd_2000`
# © ALARM Project, February 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NJ_cd_2000}")

set.seed(2000)
plans <- redist_smc(map, nsims = 6e3, runs = 5, counties = pseudo_county)

# contiguity validation
pmat  <- redist::get_plans_matrix(plans)
ok    <- check_plans_polygon_contiguity(map, pmat)

# Build a index in the same order as pmat columns
draw_index <- plans %>%
  dplyr::distinct(chain, draw) %>%
  dplyr::arrange(chain, as.integer(draw))

# Keep only the pairs that passed contiguity
keep_pairs <- draw_index[ok, ]

# Filter original plans object
plans <- plans %>%
  dplyr::inner_join(keep_pairs, by = c("chain", "draw"))

# Thin samples
plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
  ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NJ_2000/NJ_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NJ_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NJ_2000/NJ_cd_2000_stats.csv")

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
    labs(title = "New Jersey Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    theme_bw()
  
  # Total Black districts that are performing
  plans %>%
    subset_sampled() %>%
    group_by(draw) %>%
    summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
    count(n_black_perf)
