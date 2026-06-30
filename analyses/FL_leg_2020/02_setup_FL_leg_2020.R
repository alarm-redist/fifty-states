###############################################################################
# Set up redistricting simulation for `FL_leg_2020`
# © ALARM Project, May 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg FL_leg_2020}")

map_ssd <- redist_map(fl_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = fl_shp$adj)

map_shd <- redist_map(fl_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = fl_shp$adj)

# merged maps: use these only for simulation
map_ssd_merged <- map_ssd |>
  merge_by(merge_group, drop_geom = TRUE)
map_shd_merged <- map_shd |>
  merge_by(merge_group, drop_geom = TRUE)

# Pseudo-county on merged simulation map
map_ssd_merged <- map_ssd_merged |>
    mutate(pseudo_county = pick_county_muni(map_ssd_merged, counties = county, munis = muni,
        pop_muni = get_target(map_ssd_merged)))
map_shd_merged <- map_shd_merged |>
    mutate(pseudo_county = pick_county_muni(map_shd_merged, counties = county, munis = muni,
        pop_muni = get_target(map_shd_merged)))

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "FL_SSD_2020"
attr(map_shd, "analysis_name") <- "FL_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/FL_2020/FL_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/FL_2020/FL_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
