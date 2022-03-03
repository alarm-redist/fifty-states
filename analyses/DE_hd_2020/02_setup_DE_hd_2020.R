###############################################################################
# Set up redistricting simulation for `DE_hd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg DE_hd_2020}")

map <- redist_map(de_shp, pop_tol = 0.05,
    existing_plan = cd_2020, adj = de_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "DE_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/DE_2020/DE_hd_2020_map.rds", compress = "xz")
cli_process_done()
