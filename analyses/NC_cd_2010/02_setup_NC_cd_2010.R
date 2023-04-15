###############################################################################
# Set up redistricting simulation for `NC_cd_2010`
# © ALARM Project, April 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NC_cd_2010}")

map <- redist_map(nc_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = nc_shp$adj)

# Fix labeling
map$state <- "NC"

# Add an analysis name attribute
attr(map, "analysis_name") <- "NC_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NC_2010/NC_cd_2010_map.rds", compress = "xz")
cli_process_done()
