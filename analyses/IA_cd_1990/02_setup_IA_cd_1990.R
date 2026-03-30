###############################################################################
# Set up redistricting simulation for `IA_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IA_cd_1990}")

# pop tol set lower because of no county split constraints
map <- redist_map(ia_shp, pop_tol = 0.0001,
    existing_plan = cd_1990, adj = ia_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "IA_1990"

# fix state label on map
map$state <- "IA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IA_1990/IA_cd_1990_map.rds", compress = "xz")
cli_process_done()
