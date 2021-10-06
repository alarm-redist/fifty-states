###############################################################################
# Set up redistricting simulation for `CO_cd_2020`
# © ALARM Project, October 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CO_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(co_shp, pop_tol = 0.005,
                  ndists = 8, adj = co_shp$adj)

# TODO any filtering, cores, merging, etc.

# Add an analysis name attribute ----
attr(map, "analysis_name") <- "CO_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CO_2020/CO_cd_2020_map.rds", compress = "xz")
cli_process_done()
