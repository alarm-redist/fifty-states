###############################################################################
# Simulate plans for `UT_shd_2020` SHD
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg UT_shd_2020}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 550

# Softly penalize total county splits to move the ensemble
# closer to the enacted plan.
constr <- redist_constr(map_shd)
constr <- add_constr_total_splits(
  constr,
  strength = 2,
  admin = map_shd$county
)

plans <- redist_smc(
  map_shd,
  nsims = 2e3, runs = 5,
  ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1")),
  counties = pseudo_county,
  constraints = constr,
  sampling_space = "linking_edge",
  ms_params = list(
    frequency = 1L,
    mh_accept_per_smc = mh_accept_per_smc
  ),
  split_params = list(
    splitting_schedule = "any_valid_sizes"
  ),
  verbose = TRUE
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/UT_2020/UT_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg UT_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/UT_2020/UT_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)

    # Extra validation plots for custom constraints -----
    # TODO remove this section if no custom constraints
}
