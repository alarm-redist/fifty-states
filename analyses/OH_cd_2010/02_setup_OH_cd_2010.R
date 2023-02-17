###############################################################################
# Set up redistricting simulation for `OH_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OH_cd_2020}")

map <- redist_map(oh_shp, pop_tol = 0.005,
                  existing_plan = cd_2010, adj = oh_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "OH_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OH_2010/OH_cd_2010_map.rds", compress = "xz")
cli_process_done()
