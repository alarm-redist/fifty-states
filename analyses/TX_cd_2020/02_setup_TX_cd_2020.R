###############################################################################
# Set up redistricting simulation for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TX_cd_2020}")

map <- redist_map(tx_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = tx_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "TX_2020"

# Unique ID for each row, will use later to reconnect pieces
map$row_id <- 1:nrow(map)

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TX_2020/TX_cd_2020_map.rds", compress = "xz")
cli_process_done()
