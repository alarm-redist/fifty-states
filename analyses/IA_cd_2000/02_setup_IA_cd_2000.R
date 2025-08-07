###############################################################################
# Set up redistricting simulation for `IA_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IA_cd_2000}")

# pop tol set lower because of no county split constraints
map <- redist_map(ia_shp, pop_tol = 0.0001,
    existing_plan = cd_2000, adj = ia_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "IA_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IA_2000/IA_cd_2000_map.rds", compress = "xz")
cli_process_done()
