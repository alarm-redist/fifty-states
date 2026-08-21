###############################################################################
# Simulate plans for `LA_ssd_2020` SSD
# © ALARM Project, June 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 550

constr <- redist_constr(map_ssd) |>
  add_constr_grp_hinge(-1, vap_black, vap, 0.50) |>
  add_constr_grp_hinge(8,  vap_black, vap, 0.55) |>
  add_constr_grp_hinge(6,  vap_black, vap, 0.60) |>
  add_constr_grp_inv_hinge(1.5, vap_black, vap, 0.78)

plans <- redist_smc(
  map_ssd,
  nsims = 2e3, runs = 5,
  ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")),
  counties = ssd_2010,
  constraints = constr,
  pop_temper = 0.05,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/LA_2020/LA_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_2020/LA_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
    summary(plans)

    # core preservation
    p_core <- plans |>
      match_numbers(map_ssd$ssd_2010) |>
      hist(pop_overlap)

    print(p_core)

    # enacted black VAP performance
    enacted_perf <- plans |>
      filter(draw == "ssd_2020") |>
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
      labs(title = "Louisiana Enacted Senate Plan versus Simulations") +
      scale_color_manual(values = c(ssd_2020 = "black")) +
      theme_bw()

    print(p_bvap)

}
