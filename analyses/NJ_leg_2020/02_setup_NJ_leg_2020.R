###############################################################################
# Set up redistricting simulation for `NJ_leg_2020`
# © ALARM Project, June 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_leg_2020}")

# Pre-computation
# New Jersey's total population in 2020
TOTAL_POP_NJ = 9288994

nj_shp <- nj_shp |>
  group_by(mcd) |>
  mutate(total_pop_per_muni = sum(pop)) |>
  ungroup() |>
  mutate(small_muni = total_pop_per_muni < ((1/40)*TOTAL_POP_NJ)) |>
  # create merge group
  mutate(merge_group = if_else(small_muni, mcd, as.character(row_number())))

map_ssd <- redist_map(nj_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = nj_shp$adj)

map_shd <- redist_map(nj_shp, pop_tol = 0.05,
    existing_plan = shd_2020, adj = nj_shp$adj)

# Merge small municipalities
map_ssd_merged <- map_ssd |>
  merge_by(merge_group, drop_geom = FALSE) |>
  select(-total_pop_per_muni, -small_muni, -merge_group)

map_shd_merged <- map_shd |>
  merge_by(merge_group, drop_geom = FALSE) |>
  select(-total_pop_per_muni, -small_muni, -merge_group)

# Add total splits constraint
constr <- redist_constr(map_shd_merged) |>
add_constr_total_splits(strength = 2.4, admin = map_shd_merged$muni)

# make pseudo counties with default settings
map_ssd_merged <- map_ssd_merged |>
    mutate(pseudo_county = pick_county_muni(map_ssd_merged, counties = county, munis = muni,
                                            pop_muni = get_target(map_ssd_merged)))
map_shd_merged <- map_shd_merged |>
    mutate(pseudo_county = pick_county_muni(map_shd_merged, counties = county, munis = muni,
                                            pop_muni = 3*get_target(map_shd_merged)))

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "NJ_SSD_2020"
attr(map_shd, "analysis_name") <- "NJ_SHD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/NJ_2020/NJ_leg_2020_map_ssd.rds", compress = "xz")
write_rds(map_shd, "data-out/NJ_2020/NJ_leg_2020_map_shd.rds", compress = "xz")
cli_process_done()
