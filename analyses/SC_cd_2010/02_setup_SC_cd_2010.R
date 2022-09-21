###############################################################################
# Set up redistricting simulation for `SC_cd_2010`
# © ALARM Project, June 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg SC_cd_2010}")

map <- redist_map(sc_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = sc_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "SC_2010"

# Fix labeling
map$state <- "SC"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/SC_2010/SC_cd_2010_map.rds", compress = "xz")
cli_process_done()
