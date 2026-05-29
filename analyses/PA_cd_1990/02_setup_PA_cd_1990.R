###############################################################################
# Set up redistricting simulation for `PA_cd_1990`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg PA_cd_1990}")

map <- redist_map(pa_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = pa_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "PA_1990"

map$state <- "PA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/PA_1990/PA_cd_1990_map.rds", compress = "xz")
cli_process_done()
