###############################################################################
# Set up redistricting simulation for `MN_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MN_cd_2000}")

map <- redist_map(mn_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = mn_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))
# Add an analysis name attribute
attr(map, "analysis_name") <- "MN_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MN_2000/MN_cd_2000_map.rds", compress = "xz")
cli_process_done()
