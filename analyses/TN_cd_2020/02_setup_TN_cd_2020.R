###############################################################################
# Set up redistricting simulation for `TN_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TN_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(tn_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = tn_shp$adj)

# TODO any filtering, cores, merging, etc.

# Add an analysis name attribute
attr(map, "analysis_name") <- "TN_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TN_2020/TN_cd_2020_map.rds", compress = "xz")
cli_process_done()
