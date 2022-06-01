###############################################################################
# Set up redistricting simulation for `SC_cd_2020`
# © ALARM Project, April 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg SC_cd_2020}")

map <- sc_shp %>%
    redist_map(pop_tol = 0.005,
               existing_plan = cd_2020,
               adj = sc_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "SC_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/SC_2020/SC_cd_2020_map.rds", compress = "xz")
cli_process_done()
