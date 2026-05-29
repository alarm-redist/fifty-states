###############################################################################
# Set up redistricting simulation for `NE_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NE_cd_1990}")

map <- redist_map(ne_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = ne_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NE_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NE_1990/NE_cd_1990_map.rds", compress = "xz")
cli_process_done()
