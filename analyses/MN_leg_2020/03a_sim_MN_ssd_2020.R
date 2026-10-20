###############################################################################
# Simulate plans for `MN_ssd_2020` SSD
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MN_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 130

constr <- redist_constr(map_ssd) %>%
    add_constr_total_plan_splits(strength = 1.85, admin = map_ssd$county_muni)

plans <- redist_smc(
    map_ssd,
    nsims = 7500, runs = 5,
    counties = pseudo_county,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    constraints = constr,
    pop_temper = 0.02,
    ncores = 64
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- match_numbers(plans, "ssd_2020")

write_rds(plans, here("data-raw/MN/MN_ssd_2020_plans_oversample.rds"), compress = "xz")
