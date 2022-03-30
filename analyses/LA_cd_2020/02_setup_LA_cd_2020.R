###############################################################################
# Set up redistricting simulation for `LA_cd_2020`
# © ALARM Project, March 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg LA_cd_2020}")

map <- redist_map(la_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = la_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map))) %>%
    mutate(core_id = redist.identify.cores(adj, cd_2020, boundary = 2))
map_m <- merge_by(map, core_id)

# Add an analysis name attribute
attr(map, "analysis_name") <- "LA_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/LA_2020/LA_cd_2020_map.rds", compress = "xz")
cli_process_done()
