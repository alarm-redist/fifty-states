###############################################################################
# Set up redistricting simulation for `RI_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg RI_cd_2020}")

map <- redist_map(ri_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ri_shp$adj)
map$sd_2020 <- ri_shp$sd_2020

# Add an analysis name attribute
attr(map, "analysis_name") <- "RI_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/RI_2020/RI_cd_2020_map.rds", compress = "xz")
cli_process_done()
