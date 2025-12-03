###############################################################################
# Simulate plans for `TX_ssd_2020` SSD
# © ALARM Project, October 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_ssd_2020}")

# VRA constraints
constraints <- redist_constr(map_ssd) %>%
  add_constr_grp_hinge(
    12,
    cvap_hisp,
    total_pop = cvap,
    tgts_group = c(0.45)
  ) %>%
  add_constr_grp_hinge(
    10,
    cvap_black,
    total_pop = cvap,
    tgts_group = c(0.45))

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 20

plans <- redist_smc(
  map_ssd,
  nsims = 2e3, runs = 5,
  counties = pseudo_county,
  constraints = constraints,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2020) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TX_2020/TX_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd) |>
  mutate(total_cvap = tally_var(map_ssd, cvap), .after = total_vap)

# cvap columns
cvap_cols <- names(map_ssd)[tidyselect::eval_select(starts_with("cvap_"), map_ssd)]
for (col in rev(cvap_cols)) {
  plans <- mutate(plans, {{ col }} := tally_var(map_ssd, map_ssd[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2020/TX_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_ssd)
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
    p3 <- redist.plot.hist(psum, rep_hvap) + xlab("HCVAP > .4 & Rep > Dem")
    p4 <- redist.plot.hist(psum, dem_bvap) + xlab("BVAP > .4 & Dem > Rep")
    p5 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian CVAP > .5")
    p6 <- redist.plot.hist(psum, mmd_coalition_dem) + xlab("Hisp + Black + Asian CVAP > .5 & Dem > Rep")
    
    p1 + p2 + p3 + p4 + p5 + p6
}
