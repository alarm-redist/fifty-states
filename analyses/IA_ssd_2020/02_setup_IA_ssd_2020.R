###############################################################################
# Set up redistricting simulation for ```SLUG```
# ``COPYRIGHT``
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IA_ssd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(ia_shp, pop_tol = 0.005,
    existing_plan = ssd_2020, adj = ia_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "IA_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IA_2020/IA_ssd_2020_map.rds", compress = "xz")
cli_process_done()
