###############################################################################
# Set up redistricting simulation for `NH_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NH_cd_1990}")

map <- redist_map(nh_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = nh_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NH_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NH_1990/NH_cd_1990_map.rds", compress = "xz")
cli_process_done()
