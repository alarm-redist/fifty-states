###############################################################################
# Set up redistricting simulation for `OR_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OR_cd_2000}")

map <- redist_map(or_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = or_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "OR_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OR_2000/OR_cd_2000_map.rds", compress = "xz")
cli_process_done()
