###############################################################################
# Set up redistricting simulation for `WV_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg WV_cd_2000}")

map <- redist_map(wv_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = wv_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "WV_2000"

map$state <- "WV"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/WV_2000/WV_cd_2000_map.rds", compress = "xz")
cli_process_done()
