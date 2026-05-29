###############################################################################
# Set up redistricting simulation for `IN_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IN_cd_1990}")

map <- redist_map(in_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = in_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "IN_1990"

map$state <- "IN"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IN_1990/IN_cd_1990_map.rds", compress = "xz")
cli_process_done()
