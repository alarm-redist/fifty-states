###############################################################################
# Simulate plans for `MD_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MD_cd_2010}")

set.seed(2010)

plans <- redist_smc(
    map,
    nsims = 2500, runs = 2L,
    counties = county
)

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MD_2010/MD_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MD_cd_2010}")

plans <- add_summary_stats(plans, map)

plans <- plans |> select(-ends_with('.y')) |> rename_with(.fn = \(x) str_sub(x, end = -3), .cols = ends_with('.x'))

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MD_2010/MD_cd_2010_stats.csv")

cli_process_done()

