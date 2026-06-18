###############################################################################
# Set up redistricting simulation for `PA_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg PA_cd_2000}")

map <- redist_map(pa_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = pa_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "PA_2000"

map$state <- "PA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/PA_2000/PA_cd_2000_map.rds", compress = "xz")
cli_process_done()
