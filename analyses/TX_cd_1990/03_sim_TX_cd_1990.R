###############################################################################
# Simulate plans for `TX_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_1990}")

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),
  error = function(e) "linking_edge"
)

constr <- redist_constr(map) |>
  add_constr_grp_hinge(
    4,
    vap_hisp,
    total_pop = vap,
    tgts_group = c(0.6)
  ) |>
  add_constr_grp_inv_hinge(
    2,
    vap_hisp,
    total_pop = vap,
    tgts_group = c(0.75)
  ) |>
  add_constr_grp_hinge(
    2,
    vap_black,
    total_pop = vap,
    tgts_group = c(0.35))

set.seed(1990)

plans <- redist_smc(map,
                    nsims = 1e3,
                    runs = 5,
                    counties = pseudo_county,
                    constraints = constr,
                    sampling_space = sampling_space_val,
                    ms_params = list(frequency = 1L, mh_accept_per_smc = 40),
                    split_params = list(splitting_schedule = "any_valid_sizes"),
                    verbose = T, pop_temper = 0.01)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TX_1990/TX_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_1990/TX_cd_1990_stats.csv")

cli_process_done()

summary(plans)
validate_analysis(plans, map)