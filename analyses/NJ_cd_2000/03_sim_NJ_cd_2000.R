################################################################################
# Simulate plans for `NJ_cd_2000`
# © ALARM Project, March 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NJ_cd_2000}")

BVAP_THRESH <- 0.30
DEM_THRESH  <- 0.50
ndists <- attr(map, "ndists")

constr <- redist_constr(map) |>
    add_constr_min_group_frac(
        strength      = -1,
        group_pops    = list(map$vap_black, map$ndv),
        total_pops    = list(map$vap, map$nrv + map$ndv),
        min_fracs     = c(BVAP_THRESH, DEM_THRESH),
        thresh        = -0.9,
        only_nregions = ndists
    )

set.seed(2000)
plans <- redist_smc(map,
    nsims = 1e3,
    runs = 5,
    counties = pseudo_county,
    constraints = constr,
    sampling_space = "spanning_forest",
    ms_params = list(frequency = 1L, mh_accept_per_smc = 20),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = T, pop_temper = 0.01)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NJ_2000/NJ_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NJ_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NJ_2000/NJ_cd_2000_stats.csv")

cli_process_done()
