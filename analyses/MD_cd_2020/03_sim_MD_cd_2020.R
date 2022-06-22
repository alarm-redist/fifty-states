###############################################################################
# Simulate plans for `MD_cd_2020`
# © ALARM Project, November 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MD_cd_2020}")

set.seed(2020)

plans <- redist_smc(
    map,
    nsims = 5e3, runs = 2L, ncores = 8,
    counties = county
)

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MD_2020/MD_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MD_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MD_2020/MD_cd_2020_stats.csv")

cli_process_done()
