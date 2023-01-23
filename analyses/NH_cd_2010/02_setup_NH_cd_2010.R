###############################################################################
# Set up redistricting simulation for `NH_cd_2010`
# © ALARM Project, September 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NH_cd_2010}")

map <- redist_map(nh_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = nh_shp$adj) %>% mutate(state = "NH")

# Add an analysis name attribute
attr(map, "analysis_name") <- "NH_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NH_2010/NH_cd_2010_map.rds", compress = "xz")
cli_process_done()
