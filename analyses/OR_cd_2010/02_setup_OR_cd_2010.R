###############################################################################
# Set up redistricting simulation for `OR_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OR_cd_2010}")

map <- redist_map(or_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = or_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "OR_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OR_2010/OR_cd_2010_map.rds", compress = "xz")
cli_process_done()
