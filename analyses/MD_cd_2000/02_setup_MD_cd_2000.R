###############################################################################
# Set up redistricting simulation for `MD_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_2000}")

map <- redist_map(md_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = wv_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MD_2000"

map$state <- "MD"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MD_2000/MD_cd_2000_map.rds", compress = "xz")
cli_process_done()
