###############################################################################
# Set up redistricting simulation for `WI_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg WI_cd_2020}")

map <- redist_map(wi_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = wi_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "WI_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/WI_2020/WI_cd_2020_map.rds", compress = "xz")
cli_process_done()
