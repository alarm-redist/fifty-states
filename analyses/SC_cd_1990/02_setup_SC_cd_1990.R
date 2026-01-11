###############################################################################
# Set up redistricting simulation for `SC_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg SC_cd_1990}")

map <- redist_map(sc_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = sc_shp$adj)
# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "SC_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/SC_1990/SC_cd_1990_map.rds", compress = "xz")
cli_process_done()
