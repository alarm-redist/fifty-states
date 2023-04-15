###############################################################################
# Simulate plans for `ID_cd_2010`
# © ALARM Project, March 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ID_cd_2010}")

set.seed(2010)
plans <- redist_smc(map,
    nsims = 15e3,
    runs = 2L,
    counties = county_muni)

plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/ID_2010/ID_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ID_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/ID_2010/ID_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.adj(id_shp, id_shp$adj, plan = redist.sink.plan(id_shp$county)) +
        geom_sf(data = tigris::primary_secondary_roads("ID"), color = "red") +
        theme_void() +
        guides(fill = "none")
}

