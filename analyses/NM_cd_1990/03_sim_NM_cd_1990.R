###############################################################################
# Simulate plans for `NM_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NM_cd_1990}")

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
set.seed(1990)
plans <- redist_smc(map,
                    nsims = 2000,
                    runs = 10,
                    counties = pseudo_county,
                    pop_temper = 0.05,
                    seq_alpha  = 0.9,
)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NM_1990/NM_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NM_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NM_1990/NM_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
