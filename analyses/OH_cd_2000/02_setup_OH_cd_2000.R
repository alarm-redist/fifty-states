###############################################################################
# Set up redistricting simulation for `OH_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OH_cd_2000}")

map <- redist_map(oh_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = oh_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "OH_2000"

map$state <- "OH"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OH_2000/OH_cd_2000_map.rds", compress = "xz")
cli_process_done()
