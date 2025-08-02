###############################################################################
# Set up redistricting simulation for `MI_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MI_cd_2000}")

map <- redist_map(mi_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = mi_shp$adj)

# Pseudo-county
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
attr(map, "analysis_name") <- "MI_2000"

map$state <- "MI"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MI_2000/MI_cd_2000_map.rds", compress = "xz")
cli_process_done()
