###############################################################################
# Set up redistricting simulation for `OH_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OH_cd_1990}")

map <- redist_map(oh_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = oh_shp$adj)
# make pseudo counties with default settings
map <- map |>
  mutate(
    pseudo_county = pick_county_muni(
      map, counties = county, munis = muni,
      pop_muni = 0.4*get_target(map)
    )
  )

# Add an analysis name attribute
attr(map, "analysis_name") <- "OH_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OH_1990/OH_cd_1990_map.rds", compress = "xz")
cli_process_done()
