###############################################################################
# Simulate plans for `FL_shd_2020` SHD
# © ALARM Project, November 2025
###############################################################################

suppressMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(redist)
  library(geomander)
  library(cli)
  library(here)
  library(tinytiger)
  devtools::load_all() # load utilities
})

map_shd <- read_rds("data-out/FL_2020/FL_leg_2020_map_shd.rds")

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_shd_2020}")

sink("analyses/FL_leg_2020/output.txt")

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
mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 20

bvap_thresh  <- 0.35
ndists <- attr(map_shd, "ndists")
first_thresh <- round(ndists * .1)
second_thresh <- round(ndists * .2)

constr <- redist_constr(map_shd) |>
  add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map_shd$cvap_black),
    total_pops=list(map_shd$cvap),
    min_fracs=c(bvap_thresh),
    thresh = -5.9,
    only_nregions = seq.int(first_thresh, ndists)
  ) |> 
  add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map_shd$cvap_black),
    total_pops=list(map_shd$cvap),
    min_fracs=c(bvap_thresh),
    thresh = -7.9,
    only_nregions = seq.int(second_thresh, ndists)
  ) |>
  add_constr_grp_hinge(4, cvap_black, cvap, 0.4) |>
  add_constr_grp_hinge(-5, cvap_black, vap, 0.1) |>
  add_constr_grp_hinge(4, cvap_hisp, cvap, 0.4) |>
  add_constr_grp_hinge(-5, cvap_hisp, cvap, 0.1)

plans <- redist_smc(
  map_shd,
  nsims = 3750, runs = 5,
  constraints = constr,
  counties = pseudo_county,
  sampling_space = "spanning_forest",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE, ncores = parallelly::availableCores() - 1,
  pop_temper = 0.01
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
  ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2020/FL_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_shd_2020}")

plans <- add_summary_stats(plans, map_shd) |>
  mutate(total_cvap = tally_var(map_shd, cvap), .after = total_vap)

cvap_cols <- names(map_shd)[tidyselect::eval_select(starts_with("cvap_"), map_shd)]
for (col in rev(cvap_cols)) {
  plans <- mutate(plans, {{ col }} := tally_var(map_shd, map_shd[[col]]), .after = vap_two)
}
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2020/FL_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  validate_analysis(plans, map_shd)
  summary(plans)
  
  # Extra validation plots for custom constraints -----
  # TODO remove this section if no custom constraints
  
  psum <- plans %>%
    group_by(draw) %>%
    summarise(
      all_hvap = sum((cvap_hisp/total_cvap) > 0.4),
      dem_hvap = sum((cvap_hisp/total_cvap) > 0.4 &
                       (ndv > nrv)),
      rep_hvap = sum((cvap_hisp/total_cvap) > 0.4 &
                       (nrv > ndv)),
      all_bvap = sum((cvap_black/total_cvap) > 0.4),
      dem_bvap = sum((cvap_black/total_cvap) > 0.4 &
                       (ndv > nrv)),
      mmd_coalition = sum(((
        cvap_hisp + cvap_black + cvap_asian
      )/total_cvap) > 0.5),
      mmd_coalition_dem = sum(((
        cvap_hisp + cvap_black + cvap_asian
      )/total_cvap) > 0.5 &
        (ndv > nrv))
    )
  
  p1 <- redist.plot.hist(psum, all_hvap) + xlab("HCVAP > .4")
  p2 <- redist.plot.hist(psum, dem_hvap) + xlab("HCVAP > .4 & Dem > Rep")
  p3 <- redist.plot.hist(psum, all_bvap) + xlab("BCVAP > .4")
  p4 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian CVAP > .5")
  p5 <- redist.plot.hist(psum, mmd_coalition_dem) + xlab("Hisp + Black + Asian CVAP > .5 & Dem > Rep")
  
  p1 + p2 + p3 + p4 + p5
}
