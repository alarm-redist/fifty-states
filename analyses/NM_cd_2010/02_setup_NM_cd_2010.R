###############################################################################
# Set up redistricting simulation for `NM_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NM_cd_2010}")

# Define map
map <- redist_map(nm_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = nm_shp$adj)

# Set up cores objects
map <- map %>%
    mutate(cores = make_cores(boundary = 2))

# merge by both cores and county to preserve county contiguity
map_cores <- merge_by(map, cores, county)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NM_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NM_2010/NM_cd_2010_map.rds", compress = "xz")
cli_process_done()
