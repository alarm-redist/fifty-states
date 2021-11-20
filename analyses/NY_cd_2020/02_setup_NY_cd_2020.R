###############################################################################
# Set up redistricting simulation for `NY_cd_2020`
# © ALARM Project, November 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NY_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(ny_shp, pop_tol = 0.005,
                 existing_plan = cd_2010, adj = ny_shp$adj)

# TODO any filtering, cores, merging, etc.

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NY_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NY_2020/NY_cd_2020_map.rds", compress = "xz")
cli_process_done()
