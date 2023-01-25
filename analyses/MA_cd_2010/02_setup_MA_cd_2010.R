###############################################################################
# Set up redistricting simulation for `MA_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MA_cd_2010}")

map <- redist_map(ma_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ma_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MA_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MA_2010/MA_cd_2010_map.rds", compress = "xz")
cli_process_done()
