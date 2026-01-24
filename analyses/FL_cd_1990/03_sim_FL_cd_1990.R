###############################################################################
# Simulate plans for `FL_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_cd_1990}")

# Hinge constraints
constraints <- redist_constr(map) %>%
  add_constr_grp_hinge(5,  vap_black, vap, .45) %>%
  add_constr_grp_hinge(-7, vap_black, vap, .2)  %>%
  add_constr_grp_hinge(5,  vap_hisp,  vap, .55) %>%
  add_constr_grp_hinge(-7, vap_hisp,  vap, .25) %>%
  add_constr_grp_hinge(
    12,
    vap_hisp,
    total_pop = vap,
    tgts_group = c(0.50)
  ) %>%
  add_constr_grp_hinge(
    12,
    vap_black,
    total_pop = vap,
    tgts_group = c(0.50)
  )

sampling_space_val <- tryCatch(getFromNamespace("LINKING_EDGE_SPACE", "redist"),
                               error = function(e) "linking_edge")

set.seed(1990)
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

plans <- plans %>% filter(draw != "cd_1990") %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_1990)

plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_1990/FL_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_1990/FL_cd_1990_stats.csv")

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
    color = ifelse(
      subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
      "#3D77BB",
      "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_1990 = "black"))
  
  d2 <- redist.plot.distr_qtys(
    plans,
    vap_hisp/total_vap,
    color_thresh = NULL,
    color = ifelse(
      subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
      "#3D77BB",
      "#B25D4C"
    ),
    size = 0.5,
    alpha = 0.5
  ) +
    scale_y_continuous("Percent Hispanic by VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_1990 = "black"))
  
  d3 <-
    redist.plot.distr_qtys(
      plans,
      (vap_hisp + vap_black)/total_vap,
      color_thresh = NULL,
      color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB",
        "#B25D4C"
      ),
      size = 0.5,
      alpha = 0.5
    ) +
    scale_y_continuous("HVAP + BVAP / VAP") +
    labs(title = "FL Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_1990 = "black"))
  
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
      dem_hvap = sum((vap_hisp/total_vap) > 0.4 &
                       (ndv > nrv)),
      rep_hvap = sum((vap_hisp/total_vap) > 0.4 &
                       (nrv > ndv)),
      all_bvap_40 = sum((vap_black/total_vap) > 0.4),
      all_bvap_25 = sum((vap_black/total_vap) > 0.25),
      dem_bvap_25 = sum((vap_black/total_vap) > .25 & (ndv > nrv)),
      mmd_all = sum(vap_nonwhite/total_vap > 0.5),
      mmd_coalition = sum(((
        vap_hisp + vap_black
      )/total_vap) > 0.5)
    )
  
  p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HVAP + BVAP > 0.5", y = NULL)
  p2 <-
    redist.plot.hist(psum, all_hvap) + labs(x = "HVAP > 0.4", y = NULL)
  p3 <-
    redist.plot.hist(psum, dem_hvap) + labs(x = "HVAP > 0.4 & Dem > Rep", y = NULL)
  p4 <-
    redist.plot.hist(psum, rep_hvap) + labs(x = "HVAP > 0.4 & Dem < Rep", y = NULL)
  p5 <-
    redist.plot.hist(psum, all_bvap_40) + labs(x = "BVAP > 0.4", y = NULL)
  p6 <-
    redist.plot.hist(psum, all_bvap_25) + labs(x = "BVAP > 0.25", y = NULL)
  p7 <-
    redist.plot.hist(psum, dem_bvap_25) + labs(x = "BVAP > 0.25 & Dem > Rep", y = NULL)
  
  ggsave("data-raw/FL/vap_histograms.png", p1/p2/p3/p4/p5/p6/p7, height = 10)
  
}
