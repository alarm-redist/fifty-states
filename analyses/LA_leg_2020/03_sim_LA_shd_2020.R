###############################################################################
# Simulate plans for `LA_shd_2020` SHD
# © ALARM Project, June 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 250

constr <- redist_constr(map_shd) |>
  add_constr_grp_hinge(15, vap_black, vap, 0.45) |>
  add_constr_grp_hinge(10, vap_black, vap, 0.50) |>
  add_constr_grp_hinge(4, vap_black, vap, 0.55) |>
  add_constr_grp_inv_hinge(4, vap_black, vap, 0.78) |>
  add_constr_polsby(strength = 1.8) |>
  add_constr_total_splits(3.4, admin = county)

plans <- redist_smc(
  map_shd,
  nsims = 2e3, runs = 5,
  ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")),
  counties = shd_2010,
  constraints = constr,
  pop_temper = 0.04,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/LA_2020/LA_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_2020/LA_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map_shd)
  summary(plans)

  # core preservation
  p_core <- plans |>
    match_numbers(map_shd$shd_2010) |>
    hist(pop_overlap)

  print(p_core)

  # enacted black VAP performance
  enacted_perf <- plans |>
    filter(draw == "shd_2020") |>
    summarize(enacted_black_perf = sum(vap_black / total_vap > 0.3 & ndshare > 0.5))

  print(enacted_perf)

  # simulated black VAP performance
  simulated_perf <- plans |>
    subset_sampled() |>
    group_by(draw) |>
    summarize(n_black_perf = sum(vap_black / total_vap > 0.3 & ndshare > 0.5)) |>
    count(n_black_perf)

  print(simulated_perf)

  # Black VAP performance plot
  p_bvap <- redist.plot.distr_qtys(
    plans,
    vap_black / total_vap,
    color_thresh = NULL,
    color = ifelse(
      subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
      "#3D77BB",
      "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "Louisiana Enacted House Plan versus Simulations") +
    scale_color_manual(values = c(shd_2020 = "black")) +
    theme_bw()

  print(p_bvap)

}


