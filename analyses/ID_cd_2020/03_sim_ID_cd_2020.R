###############################################################################
# Simulate plans for `ID_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ID_cd_2020}")

plans <- redist_smc(map, nsims = 5e3, counties = county)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/ID_2020/ID_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ID_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/ID_2020/ID_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.adj(id_shp, id_shp$adj, plan = redist.sink.plan(id_shp$county)) +
        geom_sf(data = tigris::primary_secondary_roads("ID"), color = "orange") +
        theme_void() +
        guides(fill = "none")
}
