###############################################################################
# Set up redistricting simulation for `NJ_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_cd_2020}")

map <- redist_map(nj_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = nj_shp$adj)

# make pseudo counties with 40% of target size
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = 0.4*get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NJ_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NJ_2020/NJ_cd_2020_map.rds", compress = "xz")
cli_process_done()
