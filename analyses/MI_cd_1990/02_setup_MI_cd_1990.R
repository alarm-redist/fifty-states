###############################################################################
# Set up redistricting simulation for `MI_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MI_cd_1990}")

map <- redist_map(mi_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = mi_shp$adj)

# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MI_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MI_1990/MI_cd_1990_map.rds", compress = "xz")
cli_process_done()
