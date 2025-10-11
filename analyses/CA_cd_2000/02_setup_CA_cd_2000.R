###############################################################################
# Set up redistricting simulation for `CA_cd_2000`
# © ALARM Project, September 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CA_cd_2000}")

adj <- ca_shp$adj

map <- redist_map(ca_shp, pop_tol = 0.005,
                  existing_plan = "cd_2000", adj = adj)

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
attr(map, "analysis_name") <- "CA_2000"

map$state <- "CA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CA_2000/CA_cd_2000_map.rds", compress = "xz")
cli_process_done()
