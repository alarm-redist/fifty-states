###############################################################################
# Simulate plans for `IL_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IL_cd_1990}")

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),
  error = function(e) "linking_edge"
)

# Hinge constraints
constr <- redist_constr(map) %>%
  # Black opportunity shaping
  add_constr_grp_hinge( 6, vap_black, vap, 0.40) %>%
  add_constr_grp_hinge(-3, vap_black, vap, 0.25) %>%
  add_constr_grp_hinge(-3, vap_black, vap, 0.08) %>%
  # Hispanic opportunity shaping
  add_constr_grp_hinge( 6, vap_hisp,  vap, 0.40) %>%
  add_constr_grp_hinge(-3, vap_hisp,  vap, 0.25) %>%
  add_constr_grp_hinge(-3, vap_hisp,  vap, 0.08)


set.seed(1990)
plans <- redist_smc(
  map, 
  nsims = 1000, 
  runs = 10, 
  counties = county,
  pop_temper = 0.01, seq_alpha = 0.90,
  sampling_space = sampling_space_val,
  ms_params      = list(frequency = 1L, mh_accept_per_smc = 40),
  split_params   = list(splitting_schedule = "any_valid_sizes"),
  constraints    = constr)

attr(plans, "existing_col") <- "cd_1990"

# Now enforce ">= 1 Black opp & >= 1 Hispanic opp" where opp = share > 0.30
plans <- plans %>%
  mutate(
    n_black_opp = sum(group_frac(map, vap_black, vap) > 0.30),
    n_hisp_opp  = sum(group_frac(map, vap_hisp,  vap) > 0.30),
    .by = draw
  ) %>%
  filter((n_black_opp >= 1 & n_hisp_opp >= 1) | draw == "cd_1990") %>%
  select(-n_black_opp, -n_hisp_opp)

# thin + match numbers
plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 500) |>
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IL_1990/IL_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IL_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IL_1990/IL_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  # General validation
  validate_analysis(plans, map)
  summary(plans)
  
  # Opportunity diagnostics: Black & Hispanic VAP
  p_black <- redist.plot.distr_qtys(
    plans, vap_black / total_vap,
    color_thresh = NULL,
    color = ifelse(
      subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
      "#3D77BB", "#B25D4C"
    ),
    size = 0.5, alpha = 0.5
  ) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "Approximate Performance (Black VAP)") +
    scale_color_manual(values = c(cd_1990 = "black")) +
    theme_bw()
  
  p_hisp <- redist.plot.distr_qtys(
    plans, vap_hisp / total_vap,
    color_thresh = NULL,
    color = ifelse(
      subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
      "#3D77BB", "#B25D4C"
    ),
    size = 0.5, alpha = 0.5
  ) +
    scale_y_continuous("Percent Hispanic by VAP") +
    labs(title = "Approximate Performance (Hispanic VAP)") +
    scale_color_manual(values = c(cd_1990 = "black")) +
    theme_bw()
  
  p_black + p_hisp
}
