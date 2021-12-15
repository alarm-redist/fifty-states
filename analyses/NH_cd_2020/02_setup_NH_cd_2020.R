###############################################################################
# Set up redistricting simulation for `NH_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NH_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(nh_shp, pop_tol = 0.005,
    existing_plan = rep_prop, adj = nh_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NH_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NH_2020/NH_cd_2020_map.rds", compress = "xz")
cli_process_done()
