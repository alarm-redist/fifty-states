###############################################################################
# Set up redistricting simulation for `VA_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg VA_cd_2000}")

map <- redist_map(va_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = va_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "VA_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/VA_2000/VA_cd_2000_map.rds", compress = "xz")
cli_process_done()
