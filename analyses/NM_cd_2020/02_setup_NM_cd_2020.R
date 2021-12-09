###############################################################################
# Set up redistricting simulation for `NM_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NM_cd_2020}")

# Define map
map <- redist_map(nm_shp, pop_tol = 0.01,
                  existing_plan = cd_2010, adj = nm_shp$adj)

# Set up pseudo-counties
map <- map %>% mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni))

# Set up cores objects
map <- map %>%
    mutate(cores = make_cores(boundary = 1)) %>%
    # Merge by both cores and pseudo_county to preserve pseudo_county contiguity
    merge_by(cores, pseudo_county, drop_geom = FALSE)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NM_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NM_2020/NM_cd_2020_map.rds", compress = "xz")
cli_process_done()
