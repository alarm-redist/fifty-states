###############################################################################
# Set up redistricting simulation for `MO_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MO_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(mo_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = mo_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MO_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MO_2020/MO_cd_2020_map.rds", compress = "xz")
cli_process_done()
