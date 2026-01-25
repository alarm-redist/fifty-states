###############################################################################
# Set up redistricting simulation for `CA_cd_1990`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CA_cd_1990}")

map <- redist_map(ca_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = ca_shp$adj)
# make pseudo counties with default settings
map <- map |>
  mutate(
    pseudo_county = pick_county_muni(
      map, counties = county, munis = muni,
      pop_muni = 0.4*get_target(map)
    )
  )

# Add an analysis name attribute
attr(map, "analysis_name") <- "CA_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CA_1990/CA_cd_1990_map.rds", compress = "xz")
cli_process_done()
