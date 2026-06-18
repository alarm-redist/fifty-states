###############################################################################
# Set up redistricting simulation for `WV_cd_1990`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg WV_cd_1990}")

map <- redist_map(wv_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = wv_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "WV_1990"

map$state <- "WV"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/WV_1990/WV_cd_1990_map.rds", compress = "xz")
cli_process_done()
