###############################################################################
# Set up redistricting simulation for `UT_cd_2010`
# © ALARM Project, November 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg UT_cd_2010}")

map <- redist_map(ut_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ut_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "UT_2010"

map$state <- "UT"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/UT_2010/UT_cd_2010_map.rds", compress = "xz")
cli_process_done()
