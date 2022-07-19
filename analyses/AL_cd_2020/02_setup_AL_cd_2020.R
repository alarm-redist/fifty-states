###############################################################################
# Set up redistricting simulation for `AL_cd_2020`
# © ALARM Project, March 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AL_cd_2020}")

map <- redist_map(al_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = al_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "AL_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AL_2020/AL_cd_2020_map.rds", compress = "xz")
cli_process_done()
