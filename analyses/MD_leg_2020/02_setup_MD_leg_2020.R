###############################################################################
# Set up redistricting simulation for `MD_leg_2020`
# © ALARM Project, August 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_leg_2020}")

# Recode the enacted House labels to numeric IDs
shd_lookup <- md_shp |>
    st_drop_geometry() |>
    distinct(shd_2020) |>
    arrange(shd_2020) |>
    mutate(shd_2020_id = row_number())

md_shp <- md_shp |>
    left_join(shd_lookup, by = "shd_2020")

map_ssd <- redist_map(md_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = md_shp$adj)

map_shd <- redist_map(md_shp, pop_tol = 0.05,
    existing_plan = shd_2020_id, adj = md_shp$adj)

# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
        pop_muni = get_target(map_ssd)))
map_shd <- map_shd |>
    mutate(pseudo_county = pick_county_muni(map_shd, counties = county, munis = muni,
        pop_muni = get_target(map_shd)))

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "MD_SSD_2020"
attr(map_shd, "analysis_name") <- "MD_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/MD_2020/MD_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/MD_2020/MD_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
