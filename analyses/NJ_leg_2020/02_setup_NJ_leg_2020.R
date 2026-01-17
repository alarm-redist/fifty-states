###############################################################################
# Set up redistricting simulation for `NJ_leg_2020`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_leg_2020}")

# TODO any pre-computation (usually not necessary)

map_ssd <- redist_map(nj_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = nj_shp$adj)

map_shd <- redist_map(nj_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = nj_shp$adj)

# TODO any filtering, cores, merging, etc.

# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
                                            pop_muni = get_target(map_ssd)))
map_shd <- map_shd |>
    mutate(pseudo_county = pick_county_muni(map_shd, counties = county, munis = muni,
                                            pop_muni = get_target(map_shd)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "NJ_SSD_2020"
attr(map_shd, "analysis_name") <- "NJ_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/NJ_2020/NJ_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/NJ_2020/NJ_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
