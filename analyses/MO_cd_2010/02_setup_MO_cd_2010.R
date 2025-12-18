###############################################################################
# Set up redistricting simulation for `MO_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MO_cd_2010}")

map <- redist_map(mo_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = mo_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MO_2010"
map$state <- "MO"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MO_2010/MO_cd_2010_map.rds", compress = "xz")
cli_process_done()
