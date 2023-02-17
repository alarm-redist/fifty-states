###############################################################################
# Set up redistricting simulation for `AZ_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AZ_cd_2010}")

map <- redist_map(az_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = az_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "AZ_2010"
map$state <- "AZ"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AZ_2010/AZ_cd_2010_map.rds", compress = "xz")
cli_process_done()
