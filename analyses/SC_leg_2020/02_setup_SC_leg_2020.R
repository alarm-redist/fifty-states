###############################################################################
# Set up redistricting simulation for `SC_leg_2020`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg SC_leg_2020}")

map_ssd <- redist_map(sc_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = sc_shp$adj)

map_shd <- redist_map(sc_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = sc_shp$adj)

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
attr(map_ssd, "analysis_name") <- "SC_SSD_2020"
attr(map_shd, "analysis_name") <- "SC_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/SC_2020/SC_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/SC_2020/SC_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
