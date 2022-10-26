###############################################################################
# Set up redistricting simulation for `NY_cd_2010`
# © ALARM Project, September 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NY_cd_2010}")

map <- redist_map(ny_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ny_shp$adj)

# Make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NY_2010"

map <- map %>% mutate(state = "NY")

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NY_2010/NY_cd_2010_map.rds", compress = "xz")
cli_process_done()
