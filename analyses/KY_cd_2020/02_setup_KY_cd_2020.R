###############################################################################
# Set up redistricting simulation for `KY_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg KY_cd_2020}")

map <- redist_map(ky_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ky_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "KY_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/KY_2020/KY_cd_2020_map.rds", compress = "xz")
cli_process_done()
