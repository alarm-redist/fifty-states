###############################################################################
# Set up redistricting simulation for `LA_leg_2020`
# © ALARM Project, June 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg LA_leg_2020}")

map_ssd <- redist_map(la_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = la_shp$adj)

map_shd <- redist_map(la_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = la_shp$adj)

# Fill missing 2010 assignments for zero-population placeholder VTDs
# using their corresponding 2020 enacted district assignments
map_ssd <- map_ssd |>
  mutate(ssd_2010 = if_else(is.na(ssd_2010), ssd_2020, ssd_2010))
map_shd <- map_shd |>
  mutate(shd_2010 = if_else(is.na(shd_2010), shd_2020, shd_2010))

# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
                                            pop_muni = get_target(map_ssd)))
map_shd <- map_shd |>
    mutate(pseudo_county = pick_county_muni(map_shd, counties = county, munis = muni,
                                            pop_muni = get_target(map_shd)))

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "LA_SSD_2020"
attr(map_shd, "analysis_name") <- "LA_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/LA_2020/LA_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/LA_2020/LA_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
