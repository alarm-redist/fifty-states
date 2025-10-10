###############################################################################
# Set up redistricting simulation for `TX_ssd_2020`
# © ALARM Project, September 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TX_ssd_2020}")

ssd_map <- redist_map(tx_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = tx_shp$adj)

# make pseudo counties with default settings
ssd_map <- ssd_map %>%
    mutate(pseudo_county = pick_county_muni(ssd_map, counties = county, munis = muni,
        pop_muni = get_target(ssd_map)))

# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(ssd_map, "analysis_name") <- "TX_2020"

# Output the redist_map object. Do not edit this path.
write_rds(ssd_map, "data-out/TX_2020/TX_ssd_2020_map.rds", compress = "xz")
cli_process_done()
