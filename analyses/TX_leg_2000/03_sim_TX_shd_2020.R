###############################################################################
# Simulate plans for `TX_shd_2020` SHD
# © ALARM Project, October 2025
###############################################################################

# Run the simulation -----
sink("analyses/TX_leg_2000/output_sf.txt")
cli_process_start("Running simulations for {.pkg TX_shd_2020}")

bvap_thresh  <- 0.4
ndists <- attr(map_shd, "ndists")

# VRA constraints
constraints <- redist_constr(map_shd) %>%
  add_constr_grp_hinge(
    3,
    cvap_hisp,
    total_pop = cvap,
    tgts_group = c(0.5)
  ) %>%
  add_constr_grp_hinge(
    8,
    cvap_black,
    total_pop = cvap,
    tgts_group = c(0.5)) |>
  add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map_shd$vap_black),
    total_pops=list(map_shd$vap),
    min_fracs=c(bvap_thresh),
    thresh = -2.9,
    only_nregions = seq.int(10, ndists)
  ) |> 
  add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map_shd$vap_black),
    total_pops=list(map_shd$vap),
    min_fracs=c(bvap_thresh),
    thresh = -4.9,
    only_nregions = seq.int(40, ndists)
  )

set.seed(2020)

mh_accept_per_smc <- n_distinct(map_shd$shd_2020)/3 + 15

plans <- redist_smc(
  map_shd,
  nsims = 3500, runs = 5,
  constraints = constraints,
  counties = pseudo_county,
  sampling_space = "spanning_forest", # linking_edge
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE, ncores = parallelly::availableCores() - 1
)

sink()

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
write_rds(plans, here("data-out/TX_2020/TX_shd_2020_plans2.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_shd_2020}")

plans <- add_summary_stats(plans, map_shd) |>
  mutate(total_cvap = tally_var(map_shd, cvap), .after = total_vap)

# cvap columns
cvap_cols <- names(map_shd)[tidyselect::eval_select(starts_with("cvap_"), map_shd)]
for (col in rev(cvap_cols)) {
  plans <- mutate(plans, {{ col }} := tally_var(map_shd, map_shd[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2020/TX_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)
    
    # Extra validation plots for custom constraints -----
    
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
        rep_bvap = sum((cvap_black/total_cvap) > 0.4 &
                         (nrv > ndv)),
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
    p4 <- redist.plot.hist(psum, dem_bvap) + xlab("BCVAP > .4 & Dem > Rep")
    p5 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian CVAP > .5")
    p6 <- redist.plot.hist(psum, mmd_coalition_dem) + xlab("Hisp + Black + Asian CVAP > .5 & Dem > Rep")
    
    p1 + p2 + p3 + p4 + p5 + p6

    # Extra validation plots for custom constraints -----
    # TODO remove this section if no custom constraints
}
