###############################################################################
# Set up redistricting simulation for `NV_cd_2010`
# © ALARM Project, September 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NV_cd_2010}")

map <- redist_map(nv_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = nv_shp$adj)

# Make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni, pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NV_2010"

# Fix state label
map$state <- "NV"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NV_2010/NV_cd_2010_map.rds", compress = "xz")
cli_process_done()
