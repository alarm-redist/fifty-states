###############################################################################
# Set up redistricting simulation for `MO_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MO_cd_1990}")

map <- redist_map(mo_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = mo_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MO_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MO_1990/MO_cd_1990_map.rds", compress = "xz")
cli_process_done()
