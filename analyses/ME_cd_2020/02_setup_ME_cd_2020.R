###############################################################################
# Set up redistricting simulation for `ME_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ME_cd_2020}")

map <- redist_map(me_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = me_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "ME_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/ME_2020/ME_cd_2020_map.rds", compress = "xz")
cli_process_done()
