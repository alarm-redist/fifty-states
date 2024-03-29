###############################################################################
# Set up redistricting simulation for `IA_cd_2010`
# © ALARM Project, November 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IA_cd_2010}")

#   Did not do any pre-computation

# pop tol set lower because of no county split constraints
map <- redist_map(ia_shp, pop_tol = 0.0001,
    existing_plan = cd_2010, adj = ia_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "IA_2010"

# fix state label on map
map$state <- "IA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IA_2010/IA_cd_2010_map.rds", compress = "xz")
cli_process_done()
