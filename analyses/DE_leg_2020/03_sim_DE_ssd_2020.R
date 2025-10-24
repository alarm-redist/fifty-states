###############################################################################
# Simulate plans for `DE_ssd_2020` SSD
# © ALARM Project, October 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg DE_ssd_2020}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(2020)

# TODO set equal to one third of number of districts, increase by 10-15 if no convergence
mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3)

plans <- redist_smc(
  map_ssd,
  nsims = 2e3, runs = 5,
  counties = pseudo_county,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/DE_2020/DE_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg DE_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/DE_2020/DE_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map_ssd)
  summary(plans)

  psum <- plans %>%
    dplyr::group_by(draw) %>%
    dplyr::summarise(
      all_hvap = sum((cvap_hisp/total_cvap) > 0.4),
      dem_hvap = sum((cvap_hisp/total_cvap) > 0.4 & (ndv > nrv)),
      rep_hvap = sum((cvap_hisp/total_cvap) > 0.4 & (nrv > ndv)),
      mmd_coalition = sum(((cvap_hisp + cvap_black + cvap_asian)/total_cvap) > 0.5),
      mmd_coalition_dem = sum(((cvap_hisp + cvap_black + cvap_asian)/total_cvap) > 0.5 & (ndv > nrv))
    )

  p1 <- redist.plot.hist(psum, all_hvap) + xlab("HCVAP > .4")
  p2 <- redist.plot.hist(psum, dem_hvap) + xlab("HCVAP > .4 & Dem > Rep")
  p3 <- redist.plot.hist(psum, rep_hvap) + xlab("HCVAP > .4 & Rep > Dem")
  p4 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian CVAP > .5")
  p5 <- redist.plot.hist(psum, mmd_coalition_dem) + xlab("Hisp + Black + Asian CVAP > .5 & Dem > Rep")

  (p1 + p2 + p3 + p4 + p5)

  ggsave("data-out/DE_2020/DE_ssd_2020_HCVAP_summary.png",
         p1 + p2 + p3 + p4 + p5, width = 10, height = 6, dpi = 300)
}
