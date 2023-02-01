###############################################################################
# Set up redistricting simulation for `NJ_cd_2010`
# © ALARM Project, January 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_cd_2010}")

map <- redist_map(nj_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = nj_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = 0.5*get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NJ_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NJ_2010/NJ_cd_2010_map.rds", compress = "xz")
cli_process_done()
