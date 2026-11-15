###############################################################################
# Simulate plans for `AK_ssd_2020` SSD
# © ALARM Project, November 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AK_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- 1400

constr <- redist_constr(map_ssd) %>%
  add_constr_total_splits(strength = 1, admin = county) %>%
  add_constr_total_splits(strength = 2, admin = county_muni) %>%
  add_constr_polsby(strength = 10)

plans <- redist_smc(
  map_ssd,
  nsims = 37*2e3, runs = 5,
  constraints = constr,
  counties = pseudo_county,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE,
  ncores = 150
)

plans <- match_numbers(plans, "ssd_2020")

write_rds(plans, here("data-raw/AK/AK_ssd_2020_plans_oversample.rds"), compress = "xz")
