###############################################################################
# Set up redistricting simulation for `LA_cd_1990`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg LA_cd_1990}")

map <- redist_map(la_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = la_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "LA_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/LA_1990/LA_cd_1990_map.rds", compress = "xz")
cli_process_done()
