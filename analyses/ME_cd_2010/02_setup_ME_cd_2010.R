###############################################################################
# Set up redistricting simulation for `ME_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ME_cd_2010}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(me_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = me_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "ME_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/ME_2010/ME_cd_2010_map.rds", compress = "xz")
cli_process_done()
