###############################################################################
# Set up redistricting simulation for `OK_cd_1990`
# © ALARM Project, January 2026
###############################################################################

cli_process_start("Creating {.cls redist_map} object for {.pkg OK_cd_1990}")

map <- redist_map(ok_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = ok_shp$adj)

# Pseudo-County
map <- map %>%
  mutate(
    pseudo_county = pick_county_muni(
      map,
      counties = county,   
      munis    = muni,     
      pop_muni = get_target(map)
    )
  )

# Add an analysis name attribute
attr(map, "analysis_name") <- "OK_1990"

map$state <- "OK"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OK_1990/OK_cd_1990_map.rds", compress = "xz")
cli_process_done()
