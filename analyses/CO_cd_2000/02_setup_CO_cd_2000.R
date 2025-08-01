###############################################################################
# Set up redistricting simulation for `CO_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CO_cd_2000}")

map <- redist_map(co_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = co_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "CO_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CO_2000/CO_cd_2000_map.rds", compress = "xz")
cli_process_done()
