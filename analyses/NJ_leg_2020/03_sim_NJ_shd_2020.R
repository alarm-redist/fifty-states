###############################################################################
# Simulate plans for `NJ_shd_2020` SHD
# © ALARM Project, June 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NJ_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd_merged$shd_2020)/3) + 125

plans <- redist_smc(
  map_shd_merged,
  nsims = 3000, runs = 5,
  constraints = constr,
  counties = pseudo_county,
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = TRUE
)

plans <- plans |>
  pullback(map = map_shd) |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()

attr(plans, "prec_pop") <- map_shd[[attr(map_shd, "pop_col")]]

plans <- match_numbers(plans, "shd_2020", total_pop = nj_shp$pop)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NJ_2020/NJ_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# The following line is uncommented when viewing validation plots
# plans <- readRDS("data-out/NJ_2020/NJ_shd_2020_plans.rds")

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NJ_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NJ_2020/NJ_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)
    validate_analysis(plans, map_shd)
    summary(plans)
}
