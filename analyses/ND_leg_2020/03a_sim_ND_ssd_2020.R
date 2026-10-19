###############################################################################
# Simulate plans for `ND_ssd_2020` SSD
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ND_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd_cores$ssd_2020)/3) + 120

constr <- redist_constr(map_ssd_cores) |>
    add_constr_total_splits(strength = 1.2, admin = county) |>
    add_constr_total_splits(strength = 0.3, admin = muni) |>
    add_constr_polsby(strength = 1.5)

plans <- redist_smc(
    map_ssd_cores,
    nsims = 5000, runs = 5,
    counties = pseudo_county,
    constraints = constr,
    ncores = 0,
    pop_temper = 0.04,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
) |> pullback(map_ssd)

plans <- match_numbers(plans, "ssd_2020")

write_rds(plans, here("data-raw/ND/ND_ssd_2020_plans_oversample.rds"), compress = "xz")
