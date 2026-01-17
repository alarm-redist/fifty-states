###############################################################################
# Set up redistricting simulation for `NV_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NV_cd_1990}")

map <- redist_map(nv_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = nv_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NV_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NV_1990/NV_cd_1990_map.rds", compress = "xz")
cli_process_done()
