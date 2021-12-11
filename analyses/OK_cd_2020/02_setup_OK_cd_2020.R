###############################################################################
# Set up redistricting simulation for `OK_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OK_cd_2020}")

map <- redist_map(ok_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ok_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni))

# Add an analysis name attribute
attr(map, "analysis_name") <- "OK_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OK_2020/OK_cd_2020_map.rds", compress = "xz")
cli_process_done()
