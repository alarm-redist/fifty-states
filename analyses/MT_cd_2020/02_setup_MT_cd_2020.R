###############################################################################
# Set up redistricting simulation for `MT_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MT_cd_2020}")

map <- redist_map(mt_shp, pop_tol = 0.005, existing_plan = cd, adj = mt_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = 50e3))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MT_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MT_2020/MT_cd_2020_map.rds", compress = "xz")
cli_process_done()
