###############################################################################
# Set up redistricting simulation for `ID_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ID_cd_2000}")

map <- redist_map(id_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = id_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "ID_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/ID_2000/ID_cd_2000_map.rds", compress = "xz")
cli_process_done()
