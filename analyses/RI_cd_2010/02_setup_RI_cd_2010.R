###############################################################################
# Set up redistricting simulation for `RI_cd_2010`
# © ALARM Project, January 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg RI_cd_2010}")

map <- redist_map(ri_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ri_shp$adj)
map$ssd_2010 <- ri_shp$ssd_2010

# Add an analysis name attribute
attr(map, "analysis_name") <- "RI_2010"
map$state <- "RI"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/RI_2010/RI_cd_2010_map.rds", compress = "xz")
cli_process_done()
