###############################################################################
# Simulate plans for `FL_shd_2020` SHD
# © ALARM Project, May 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 50

constr <- redist_constr(map_shd_merged) |>
  add_constr_total_splits(strength = 2.3, admin = map_shd_merged$county)

plans <- redist_smc(
  map_shd_merged,
  nsims = 2e3, runs = 5,
  ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")),
  counties = county,
  constraints = constr,
  compactness = 1.2,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
) |> pullback(map_shd)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2020/FL_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2020/FL_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)
}
