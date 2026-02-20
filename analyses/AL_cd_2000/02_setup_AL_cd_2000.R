###############################################################################
# Set up redistricting simulation for `AL_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AL_cd_2000}")

map <- redist_map(al_shp, pop_tol = 0.05,
    existing_plan = cd_2000, adj = al_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "AL_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AL_2000/AL_cd_2000_map.rds", compress = "xz")
cli_process_done()
