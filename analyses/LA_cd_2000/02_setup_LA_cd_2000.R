###############################################################################
# Set up redistricting simulation for `LA_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg LA_cd_2000}")

map <- redist_map(la_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = la_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "LA_2000"

map$state <- "LA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/LA_2000/LA_cd_2000_map.rds", compress = "xz")
cli_process_done()
