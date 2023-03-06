###############################################################################
# Set up redistricting simulation for `TX_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TX_cd_2010}")

map <- redist_map(tx_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = tx_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "TX_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TX_2010/TX_cd_2010_map.rds", compress = "xz")
cli_process_done()
