###############################################################################
# Simulate plans for `PA_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg PA_cd_2010}")


constr <- redist_constr(map) %>%
    add_constr_splits(0.25, coalesce(map$county_muni, "<bg>"))

set.seed(2010)
plans <- redist_smc(map,
                    nsims = 1e4, runs = 2L,
                    counties = pseudo_county,
                    verbose = TRUE, ncores = 16) %>%
    match_numbers("cd_2010")

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/PA_2010/PA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg PA_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/PA_2010/PA_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)
}
