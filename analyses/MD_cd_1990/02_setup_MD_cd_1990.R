###############################################################################
# Set up redistricting simulation for `MD_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_1990}")

map <- redist_map(md_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = md_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MD_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MD_1990/MD_cd_1990_map.rds", compress = "xz")
cli_process_done()
