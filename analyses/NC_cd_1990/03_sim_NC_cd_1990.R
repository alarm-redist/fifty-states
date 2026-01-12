###############################################################################
# Simulate plans for `NC_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_1990}")


BVAP_THRESH  <- 0.30
DEM_THRESH   <- 0.50
ndists <- attr(map, "ndists")
constr <- redist_constr(map) |>
  add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map$vap_black, map$ndv),
    total_pops=list(map$vap, map$nrv + map$ndv),
    min_fracs=c(BVAP_THRESH, DEM_THRESH),
    thresh = -.9,
    only_nregions = seq.int(2, ndists)
  ) |> add_constr_min_group_frac(
    strength=-1,
    group_pops=list(map$vap_black, map$ndv),
    total_pops=list(map$vap, map$nrv + map$ndv),
    min_fracs=c(BVAP_THRESH, DEM_THRESH),
    thresh = -1.9,
    only_nregions = seq.int(5, ndists)
  )

set.seed(1990)
plans <- redist_smc(map, nsims = 2e3, runs = 6,
                    counties = pseudo_county, constraints=constr,
                    split_params = list(splitting_schedule = "any_valid_sizes"),
                    sampling_space = "spanning_forest",
                    ms_params = list(frequency = 1, mh_accept_per_smc = 50),
                    ncores = 0)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NC_1990/NC_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NC_1990/NC_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
