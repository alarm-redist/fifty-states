###############################################################################
# Set up redistricting simulation for `IL_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IL_cd_2000}")

map <- redist_map(il_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = il_shp$adj)

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
attr(map, "analysis_name") <- "IL_2000"

map$state <- "IL"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IL_2000/IL_cd_2000_map.rds", compress = "xz")
cli_process_done()
