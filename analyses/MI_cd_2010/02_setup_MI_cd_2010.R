###############################################################################
# Set up redistricting simulation for `MI_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MI_cd_2010}")

map <- redist_map(mi_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = mi_shp$adj)

map <- map %>%
    mutate(state = "MI")

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MI_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MI_2010/MI_cd_2010_map.rds", compress = "xz")
cli_process_done()
