###############################################################################
# Set up redistricting simulation for `MN_cd_2010`
# © ALARM Project, September 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MN_cd_2010}")

map <- redist_map(mn_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = mn_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = 0.6*get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MN_2010"

# Fix labeling
map$state <- "MN"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MN_2010/MN_cd_2010_map.rds", compress = "xz")
cli_process_done()
