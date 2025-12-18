###############################################################################
# Set up redistricting simulation for `NV_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NV_cd_2000}")

map <- redist_map(nv_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = nv_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NV_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NV_2000/NV_cd_2000_map.rds", compress = "xz")
cli_process_done()
