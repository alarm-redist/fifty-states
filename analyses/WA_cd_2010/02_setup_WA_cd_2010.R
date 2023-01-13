###############################################################################
# Set up redistricting simulation for `WA_cd_2010`
# © ALARM Project, July 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg WA_cd_2010}")


map <- redist_map(wa_shp, pop_tol = 0.005,
                  existing_plan = cd_2010, adj = wa_shp$adj)


# Create pseudo counties to avoid county/municipality splitting
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "WA_2010"

map$state <- "WA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/WA_2010/WA_cd_2010_map.rds", compress = "xz")
cli_process_done()
