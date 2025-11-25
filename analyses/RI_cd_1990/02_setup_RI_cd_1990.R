###############################################################################
# Set up redistricting simulation for `RI_cd_1990`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg RI_cd_1990}")

map <- redist_map(ri_shp, pop_tol = 0.01,
    existing_plan = cd_1990, adj = ri_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "RI_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/RI_1990/RI_cd_1990_map.rds", compress = "xz")
cli_process_done()
