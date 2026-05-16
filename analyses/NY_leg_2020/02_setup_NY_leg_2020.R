###############################################################################
# Set up redistricting simulation for `NY_leg_2020`
# © ALARM Project, March 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NY_leg_2020}")

map_ssd <- redist_map(ny_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = ny_shp$adj)

map_shd <- redist_map(ny_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = ny_shp$adj)

# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
        pop_muni = get_target(map_ssd)))
map_shd <- map_shd |>
    mutate(pseudo_county = pick_county_muni(map_shd, counties = county, munis = muni,
        pop_muni = get_target(map_shd)))

map_ssd <- mutate(map_ssd,
    core_id = redist.identify.cores(map_ssd$adj, map_ssd$ssd_2010, boundary = 2),
    core_id_lump = forcats::fct_lump_n(as.character(core_id), max(ssd_2010)),
    core_id = if_else(as.logical(is_county_split(core_id_lump, county)),
        str_c(county, "_", core_id),
        as.character(core_id))) |>
    select(-core_id_lump)

map_shd <- mutate(map_shd,
    core_id = redist.identify.cores(map_shd$adj, map_shd$shd_2010, boundary = 2),
    core_id_lump = forcats::fct_lump_n(as.character(core_id), max(shd_2010)),
    core_id = if_else(as.logical(is_county_split(core_id_lump, county)),
        str_c(county, "_", core_id),
        as.character(core_id))) |>
    select(-core_id_lump)

# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.
map_cores_ssd <- merge_by(map_ssd, core_id, drop_geom = TRUE)
map_cores_shd <- merge_by(map_shd, core_id, drop_geom = TRUE)

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "NY_SSD_2020"
attr(map_shd, "analysis_name") <- "NY_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/NY_2020/NY_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/NY_2020/NY_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
