###############################################################################
# Set up redistricting simulation for `UT_cd_2020`
# © ALARM Project, October 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg UT_cd_2020}")

# Define map
map <- redist_map(ut_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ut_shp$adj)

# Set up pseudo-counties
map <- map %>% mutate(
    pseudo_county = pick_county_muni(map, counties = county, munis = muni))

# Set up cores objects
map <- map %>%
    mutate(cores = redist.identify.cores(map$adj, map$cd_2010, boundary = 2)) %>%
    # Merge by both cores and pseudo_county to preserve pseudo_county contiguity
    merge_by(cores, pseudo_county, drop_geom = FALSE)

# Add an analysis name attribute ----
attr(map, "analysis_name") <- "UT_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/UT_2020/UT_cd_2020_map.rds", compress = "xz")
cli_process_done()
