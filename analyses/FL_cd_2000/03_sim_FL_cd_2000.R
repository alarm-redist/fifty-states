###############################################################################
# Simulate plans for `FL_cd_2000`
# © ALARM Project, April 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_cd_2000}")

# Hinge constraints
constraints <- redist_constr(map) %>%
  add_constr_grp_hinge(5,  cvap_black, cvap, .45) %>%
  add_constr_grp_hinge(-7, cvap_black, cvap, .2)  %>%
  add_constr_grp_hinge(5,  cvap_hisp,  cvap, .55) %>%
  add_constr_grp_hinge(-7, cvap_hisp,  cvap, .25) %>%
  add_constr_grp_hinge(
    12,
    cvap_hisp,
    total_pop = cvap,
    tgts_group = c(0.50)
  ) %>%
  add_constr_grp_hinge(
    12,
    cvap_black,
    total_pop = cvap,
    tgts_group = c(0.50)
  )

sampling_space_val <- tryCatch(getFromNamespace("LINKING_EDGE_SPACE", "redist"),
                               error = function(e) "linking_edge")

set.seed(2000)
plans <- redist_smc(
  map, nsims = 1200, runs = 5,
  counties = pseudo_county,
  constraints = constraints,
  pop_temper = 0.05, seq_alpha = 0.95,
  sampling_space = sampling_space_val,
  ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = T
)

plans <- plans %>% filter(draw != "cd_2000") %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_2000)

plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2000/FL_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_2000}")

plans <- add_summary_stats(plans, map) %>%
  mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
  plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2000/FL_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  ## VAP charts
  d1 <- redist.plot.distr_qtys(
    plans,
    vap_black/total_vap,
    color_thresh = NULL,
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black"))
  
  d2 <- redist.plot.distr_qtys(
    plans,
    vap_hisp/total_vap,
    color_thresh = NULL,
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous("Percent Hispanic by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black"))
  
  d3 <-
    redist.plot.distr_qtys(
      plans,
      (vap_hisp + vap_black)/total_vap,
      color_thresh = NULL,
      size = 0.5,
      alpha = 0.5
    ) +
    scale_y_continuous("HVAP + BVAP / VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black"))
  
  ggsave(
    plot = d1/d2,
    filename = "data-raw/FL/vap_plots.png",
    height = 9,
    width = 9
  )
  ggsave(
    plot = d3,
    filename = "data-raw/FL/vap_sum_plots.png",
    height = 9,
    width = 9
  )
  
  # Minority opportunity district histograms
  psum <- plans %>%
    group_by(draw) %>%
    mutate(vap_nonwhite = total_vap - vap_white) %>%
    summarise(
      all_hvap = sum((vap_hisp/total_vap) > 0.4),
      all_bvap_40 = sum((vap_black/total_vap) > 0.4),
      all_bvap_25 = sum((vap_black/total_vap) > 0.25),
      mmd_all = sum(vap_nonwhite/total_vap > 0.5),
      mmd_coalition = sum(((
        vap_hisp + vap_black
      )/total_vap) > 0.5)
    )
  
  p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HVAP + BVAP > 0.5", y = NULL)
  p2 <-
    redist.plot.hist(psum, all_hvap) + labs(x = "HVAP > 0.4", y = NULL)
  p5 <-
    redist.plot.hist(psum, all_bvap_40) + labs(x = "BVAP > 0.4", y = NULL)
  p6 <-
    redist.plot.hist(psum, all_bvap_25) + labs(x = "BVAP > 0.25", y = NULL)
  
  ggsave("data-raw/FL/vap_histograms.png", p1/p2/p5/p6, height = 10)
  
  cpsum <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
    summarise(
      all_hvap = sum((cvap_hisp/total_cvap) > 0.4),
      all_bvap_40 = sum((cvap_black/total_cvap) > 0.4),
      all_bvap_25 = sum((cvap_black/total_cvap) > 0.25),
      mmd_all = sum(cvap_nonwhite/total_cvap > 0.5),
      mmd_coalition = sum(((
        cvap_hisp + cvap_black
      )/total_cvap) > 0.5)
    )
  
  p8 <-
    redist.plot.hist(cpsum, mmd_coalition) + labs(x = "HCVAP + BCVAP > 0.5", y = NULL)
  p9 <-
    redist.plot.hist(cpsum, all_hvap) + labs(x = "HCVAP > 0.4", y = NULL)
  p12 <-
    redist.plot.hist(cpsum, all_bvap_40) + labs(x = "BCVAP > 0.4", y = NULL)
  p13 <-
    redist.plot.hist(cpsum, all_bvap_25) + labs(x = "BCVAP > 0.25", y = NULL)
  
  ggsave("data-raw/FL/cvap_histograms.png", p8/p9/p12/p13, height = 10)
  
}
