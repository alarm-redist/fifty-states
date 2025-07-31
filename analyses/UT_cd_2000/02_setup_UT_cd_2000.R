###############################################################################
# Set up redistricting simulation for UT_cd_2000
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg UT_cd_2000}")

# any pre-computation (usually not necessary)

map <- redist_map(ut_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = ut_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "UT_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/UT_2000/UT_cd_2000_map.rds", compress = "xz")
cli_process_done()