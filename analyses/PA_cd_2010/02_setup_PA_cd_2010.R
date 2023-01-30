###############################################################################
# Set up redistricting simulation for `PA_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg PA_cd_2010}")

map <- redist_map(pa_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = pa_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "PA_2010"

map$state <- "PA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/PA_2010/PA_cd_2010_map.rds", compress = "xz")
cli_process_done()
