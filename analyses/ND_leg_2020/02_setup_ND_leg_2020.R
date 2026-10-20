###############################################################################
# Set up redistricting simulation for `ND_leg_2020`
# © ALARM Project, July 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ND_leg_2020}")

# Recode the enacted House labels to numeric IDs.
# (ND has character House labels like 04A/04B and 09A/09B)
shd_lookup <- nd_shp |>
    st_drop_geometry() |>
    distinct(shd_2020) |>
    arrange(shd_2020) |>
    mutate(shd_2020_id = row_number())

nd_shp <- nd_shp |>
    left_join(shd_lookup, by = "shd_2020")

map_ssd <- redist_map(nd_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = nd_shp$adj)

map_shd <- redist_map(nd_shp, pop_tol = 0.05,
    existing_plan = shd_2020_id, adj = nd_shp$adj)

# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
        pop_muni = get_target(map_ssd)))
map_shd <- map_shd |>
    mutate(pseudo_county = pick_county_muni(map_shd, counties = county, munis = muni,
        pop_muni = get_target(map_shd)))

# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.
map_ssd <- map_ssd |>
    mutate(reservation_core_id = if_else(fort_berthold, "fort_berthold_reservation",
        paste0("unit_", row_number())))
map_ssd_cores <- merge_by(map_ssd, reservation_core_id, drop_geom = FALSE)

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "ND_SSD_2020"
attr(map_shd, "analysis_name") <- "ND_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/ND_2020/ND_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/ND_2020/ND_leg_2020_map_shd.rds", compress = "xz")
write_rds(map_ssd_cores, "data-out/ND_2020/ND_leg_2020_map_ssd_cores.rds", compress = "xz")
cli_process_done()
