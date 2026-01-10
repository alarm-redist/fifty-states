###############################################################################
# Set up redistricting simulation for `KY_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg KY_cd_1990}")

map <- redist_map(ky_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = ky_shp$adj)

# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

map <- mutate(map,
              core_id = redist.identify.cores(map$adj, map$cd_1990, boundary = 2),
              core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_1990) + 1),
              core_id = if_else(as.logical(is_county_split(core_id_lump, county)),
                                str_c(county, "_", core_id),
                                as.character(core_id))) %>%
  select(-core_id_lump)
map_cores <- merge_by(map, core_id, pseudo_county)

# Add an analysis name attribute
attr(map, "analysis_name") <- "KY_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/KY_1990/KY_cd_1990_map.rds", compress = "xz")
cli_process_done()
