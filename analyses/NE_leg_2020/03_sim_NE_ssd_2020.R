###############################################################################
# Simulate plans for `NE_ssd_2020` SSD
# © ALARM Project, March 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NE_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 20

constr <- redist_constr(map_cores) |>
    add_constr_total_splits(strength = 1.7, admin = map_cores$county)

plans <- redist_smc(
    map_cores,
    nsims = 2e3, runs = 5,
    counties = pseudo_county,
    constraints = constr,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
) |> pullback(map_ssd)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NE_2020/NE_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NE_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NE_2020/NE_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)
  validate_analysis(plans, map_ssd)
  summary(plans)

  # cores preservation plot -----
  plans_nocores <- redist_smc(
    map_ssd,
    nsims = 200,
    runs = 2,
    counties = map_ssd$pseudo_county
  )

  d_overl <- bind_rows(
    with_cores = as_tibble(match_numbers(plans, map_ssd$ssd_2010)),
    no_cores = as_tibble(match_numbers(plans_nocores, map_ssd$ssd_2010)),
    .id = "run"
  )

  ggplot(d_overl, aes(reorder(district, pop_overlap), pop_overlap, color = run)) +
    geom_boxplot(coef = 1e6)
}

