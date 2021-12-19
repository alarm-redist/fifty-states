###############################################################################
# Set up redistricting simulation for `NE_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NE_cd_2020}")

map <- redist_map(ne_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ne_shp$adj)

# add cores
map <- mutate(map,
    core_id = redist.identify.cores(map$adj, map$cd_2010, boundary = 2))
map_cores <- merge_by(map, core_id)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NE_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NE_2020/NE_cd_2020_map.rds", compress = "xz")
cli_process_done()
