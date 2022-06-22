###############################################################################
# Set up redistricting simulation for `NM_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NM_cd_2020}")

# Define map
map <- redist_map(nm_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = nm_shp$adj)

# Set up cores objects
map <- map %>%
    mutate(cores = make_cores(boundary = 2)) %>%
    # merge by both cores and county to preserve county contiguity
    merge_by(cores, county, drop_geom = FALSE)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NM_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NM_2020/NM_cd_2020_map.rds", compress = "xz")
cli_process_done()
