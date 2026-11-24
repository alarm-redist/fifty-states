###############################################################################
# Simulate plans for `MD_ssd_2020` SSD
# © ALARM Project, August 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MD_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 80

constr <- redist_constr(map_ssd) |>
    add_constr_total_splits(2.1, admin = county)

plans_full <- redist_smc(
    map_ssd,
    nsims = 6500, runs = 5,
    counties = county,
    constraints = constr,
    ncores = 0,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)

plans <- match_numbers(plans, "ssd_2020")

write_rds(plans, here("data-raw/MD/MD_ssd_2020_plans_oversample.rds"), compress = "xz")
