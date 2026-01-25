###############################################################################
# Simulate plans for `FL_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_cd_1990}")

HISP_STRONG <- 0.60  # 2 districts
BVAP_STRONG <- 0.50  # 2 districts
BVAP_OPP <- 0.40  # 1 district
BVAP_LOW <- 0.10

ndists <- attr(map, "ndists")

constr <- redist_constr(map) |>
  # Hispanic CVAP: push for >= 0.60 in at least 2 districts
  add_constr_min_group_frac(
    strength      = 1,
    group_pops    = list(map$vap_hisp),
    total_pops    = list(map$vap),
    min_fracs     = c(HISP_STRONG),
    thresh        = -0.9,
    only_nregions = seq.int(2L, ndists)
  ) |>
  # Black VAP: push for >= 0.50 in at least 2 districts
  add_constr_min_group_frac(
    strength      = 4,
    group_pops    = list(map$vap_black),
    total_pops    = list(map$vap),
    min_fracs     = c(BVAP_STRONG),
    thresh        = -0.9,
    only_nregions = seq.int(2L, ndists)
  ) |>
  # Black VAP: push for >= 0.40 in at least 3 districts
  add_constr_min_group_frac(
    strength      = 4,
    group_pops    = list(map$vap_black),
    total_pops    = list(map$vap),
    min_fracs     = c(BVAP_OPP),
    thresh        = -1.9,
    only_nregions = seq.int(3L, ndists)
  ) |>
  # anti-cracking: encourage more districts with less BVAP share
  add_constr_grp_inv_hinge(
    7,
    vap_black,
    total_pop = vap,
    tgts_group = c(BVAP_LOW)
  ) |>
  # anti-packing: discourage too many supermajority Hispanic districts
  add_constr_grp_inv_hinge(
    2,
    vap_hisp,
    total_pop = vap,
    tgts_group = c(0.7)
  )

set.seed(1990)
plans <- redist_smc(
  map,
  nsims = 20000,
  runs = 10,
  counties = pseudo_county,
  constraints = constr,
  split_params = list(splitting_schedule = "any_valid_sizes"),
  sampling_space = "spanning_forest",
  ms_params = list(ms_frequency = 5L, ms_moves_multiplier = 20L),
  ncores = 112,
  pop_temper = 0.01,
  seq_alpha = 0.95,
  verbose = TRUE
)

plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_1990/FL_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_1990/FL_cd_1990_stats.csv")

cli_process_done()

# read in from fasrc (MAKE SURE TO RERUN add_summary_stats)
plans <- read_rds(
  here("data-out/FL_1990/FL_cd_1990_plans.rds")
)

map <- read_rds(
  here("data-out/FL_1990/FL_cd_1990_map.rds")
)

stats <- read_csv(
  here("data-out/FL_1990/FL_cd_1990_stats.csv")
)

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    redist.plot.distr_qtys(
      plans, vap_black/total_vap,
      color_thresh = NULL,
      color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB", "#B25D4C"),
      size = 0.5, alpha = 0.5) +
      scale_y_continuous("Percent Black by VAP") +
      labs(title = "Partisanship of seats by BVAP rank") +
      scale_color_manual(values = c(cd_1990 = "black"))

    redist.plot.distr_qtys(
      plans, vap_hisp/total_vap,
      color_thresh = NULL,
      color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        "#3D77BB", "#B25D4C"),
      size = 0.5, alpha = 0.5) +
      scale_y_continuous("Percent Hispanic by VAP") +
      labs(title = "Partisanship of seats by HVAP rank") +
      scale_color_manual(values = c(cd_1990 = "black"))

    # Dem seats by BVAP rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
      subset_sampled() %>%
      select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(bvap_rank) %>%
      summarize(dem = mean(dem))

    # Dem seats by HVAP rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(hvap = vap_hisp/total_vap, hvap_rank = rank(hvap)) %>%
      subset_sampled() %>%
      select(draw, district, hvap, hvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(hvap_rank) %>%
      summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
      count(n_black_perf)

    # Total Hispanic districts that are performing
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_hisp_perf = sum(vap_hisp/total_vap > 0.3 & ndshare > 0.5)) %>%
      count(n_hisp_perf)
}
