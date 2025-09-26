###############################################################################
# Set up redistricting simulation for ```SLUG```
# ``COPYRIGHT``
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ``SLUG``}")

# TODO any pre-computation (usually not necessary)

ssd_map <- redist_map(``state``_shp, pop_tol = 0.05,
    existing_plan = ssd_``YEAR``, adj = ``state``_shp$adj)

shd_map <- redist_map(``state``_shp, pop_tol = 0.05,
    existing_plan = shd_``YEAR``, adj = ``state``_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
ssd_map <- ssd_map %>%
    mutate(pseudo_county = pick_county_muni(ssd_map, counties = county, munis = muni,
                                            pop_muni = get_target(ssd_map)))
shd_map <- shd_map %>%
    mutate(pseudo_county = pick_county_muni(shd_map, counties = county, munis = muni,
                                            pop_muni = get_target(shd_map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(ssd_map, "analysis_name") <- "``STATE``_``YEAR``_SSD"
attr(shd_map, "analysis_name") <- "``STATE``_``YEAR``_SHD"

# Output the redist_map object. Do not edit this path.
write_rds(ssd_map, "data-out/``STATE``_``YEAR``/``SLUG``_ssd_map.rds", compress = "xz")
write_rds(shd_map, "data-out/``STATE``_``YEAR``/``SLUG``_shd_map.rds", compress = "xz")
cli_process_done()
