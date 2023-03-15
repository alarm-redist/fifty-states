###############################################################################
# Set up redistricting simulation for `ID_cd_2010`
# © ALARM Project, March 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ID_cd_2010}")

map <- redist_map(id_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = id_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "ID_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/ID_2010/ID_cd_2010_map.rds", compress = "xz")
cli_process_done()
