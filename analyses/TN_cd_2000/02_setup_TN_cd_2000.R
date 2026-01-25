###############################################################################
# Set up redistricting simulation for `TN_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TN_cd_2000}")

map <- redist_map(tn_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = tn_shp$adj)

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
attr(map, "analysis_name") <- "TN_2000"

map$state <- "TN"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TN_2000/TN_cd_2000_map.rds", compress = "xz")
cli_process_done()
