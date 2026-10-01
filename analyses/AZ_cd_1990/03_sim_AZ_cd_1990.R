###############################################################################
# Simulate plans for `AZ_cd_1990`
# © ALARM Project, September 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_1990}")

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),
  error = function(e) "linking_edge"
)

set.seed(1990)

constr_az <- redist_constr(map) %>%
  add_constr_grp_hinge(
    20,
    vap_hisp,
    vap,
    0.40,
    only_districts = TRUE
  ) %>%
  add_constr_grp_hinge(
    -20,
    vap_hisp,
    vap,
    0.22,
    only_districts = TRUE
  )

plans <- redist_smc(
  map,
  nsims = 8000,
  runs = 5,
  counties = pseudo_county,
  constraints = constr_az,
  sampling_space = sampling_space_val,
  ms_params = list(
    frequency = 1L,
    mh_accept_per_smc = 40
  ),
  split_params = list(
    splitting_schedule = "any_valid_sizes"
  ),
  pop_temper = 0.01,
  seq_alpha = 1,
  diagnostics = "all",
  verbose = TRUE
)

plans <- match_numbers(plans, "cd_1990")

# Subset plans that are not performing
n_perf <- plans |>
  mutate(
    hvap = group_frac(map, vap_hisp, vap),
    bvap = group_frac(map, vap_black, vap),
    ndshare = group_frac(map, ndv, nrv + ndv)
  ) |>
  group_by(chain, draw) |>
  summarize(
    n_hisp_black_perf = sum(
      hvap + bvap > 0.30 & ndshare > 0.50,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

plans_5k <- plans |>
  anti_join(
    filter(n_perf, !is.na(chain), n_hisp_black_perf == 0),
    by = c("chain", "draw")
  ) |>
  group_by(chain) |>
  filter(is.na(chain) | dense_rank(as.integer(draw)) <= 1000) |>
  ungroup()

# Validate the filtered sample before saving
kept <- plans_5k |>
  subset_sampled() |>
  as_tibble() |>
  distinct(chain, draw)

kept_perf <- semi_join(
  n_perf,
  kept,
  by = c("chain", "draw")
)

kept_by_chain <- count(kept, chain)

stopifnot(
  "all five chains are present" =
    nrow(kept_by_chain) == 5L,
  "each chain has exactly 1,000 sampled plans" =
    all(kept_by_chain$n == 1000L),
  "exactly 5,000 sampled plans are retained" =
    nrow(kept) == 5000L,
  "every sampled plan has a Hispanic + Black-performing district" =
    nrow(kept_perf) == 5000L &&
      all(kept_perf$n_hisp_black_perf > 0),
  "the enacted plan is retained" =
    "cd_1990" %in% as.character(plans_5k$draw)
)

cli_process_done()

# Save plans -----
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_plans object. Do not edit this path.
write_rds(plans_5k, here("data-out/AZ_1990/AZ_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_1990}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/AZ_1990/AZ_cd_1990_stats.csv")

cli_process_done()

# Validation plots -----
if (interactive()) {
  library(ggplot2)
  
  validation_plans <- plans_5k
  validation_plans$vap <- validation_plans$total_vap

  validate_analysis(validation_plans, map)
  summary(plans_5k)
  
  sampled <- subset_sampled(plans_5k)
  
  print(
    redist.plot.distr_qtys(
      plans_5k,
      (vap_hisp + vap_black) / total_vap,
      color_thresh = NULL,
      color = ifelse(
        sampled$ndshare > 0.5,
        "#3D77BB",
        "#B25D4C"
      ),
      size = 0.5,
      alpha = 0.5
    ) +
      scale_y_continuous("Hispanic + Black share of VAP") +
      labs(title = "Hispanic + Black Performance") +
      scale_color_manual(values = c(cd_1990 = "black"))
  )
  
  # Total Hispanic + Black districts that are performing
  plans_5k |>
    subset_sampled() |>
    group_by(chain, draw) |>
    summarize(
      n_hisp_black_perf = sum(
        (vap_hisp + vap_black) / total_vap > 0.30 &
          ndshare > 0.50,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    count(n_hisp_black_perf)
}
