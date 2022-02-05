###############################################################################
# Set up redistricting simulation for `VA_cd_2020`
# © ALARM Project, October 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg VA_cd_2020}")

map <- redist_map(va_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = va_shp$adj)

# Add an analysis name attribute ----
attr(map, "analysis_name") <- "VA_2020"

# Make pseudo counties with default settings ----

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni))

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/VA_2020/VA_cd_2020_map.rds", compress = "xz")
cli_process_done()
