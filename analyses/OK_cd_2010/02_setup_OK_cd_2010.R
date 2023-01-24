###############################################################################
# Set up redistricting simulation for `OK_cd_2010`
# © ALARM Project, January 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OK_cd_2010}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(ok_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ok_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# fix state label on map
map$state <- "OK"

# Add an analysis name attribute
attr(map, "analysis_name") <- "OK_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OK_2010/OK_cd_2010_map.rds", compress = "xz")
cli_process_done()
