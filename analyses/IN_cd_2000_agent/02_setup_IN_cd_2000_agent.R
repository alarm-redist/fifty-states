###############################################################################
# Set up redistricting simulation for `IN_cd_2000_agent`
# © ALARM Project, April 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IN_cd_2000_agent}")

map <- redist_map(in_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = in_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "IN_2000_agent"

map$state <- "IN"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IN_2000_agent/IN_cd_2000_agent_map.rds", compress = "xz")
cli_process_done()
