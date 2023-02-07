###############################################################################
# Set up redistricting simulation for `AR_cd_2010`
# © ALARM Project, November 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AR_cd_2010}")

map <- redist_map(ar_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ar_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "AR_2010"

map$state <- "AR"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AR_2010/AR_cd_2010_map.rds", compress = "xz")
cli_process_done()
