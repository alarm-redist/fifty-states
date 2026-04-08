###############################################################################
# Set up redistricting simulation for `IN_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IN_cd_2000}")

# any pre-computation (usually not necessary)

map <- redist_map(in_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = in_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "IN_2000"

map$state <- "IN"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IN_2000/IN_cd_2000_map.rds", compress = "xz")
cli_process_done()
