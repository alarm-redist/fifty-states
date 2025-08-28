###############################################################################
# Set up redistricting simulation for `CA_cd_2000`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CA_cd_2000}")

adj0 <- redist.adjacency(ca_shp)

map <- redist_map(ca_shp, pop_tol = 0.005,
                  existing_plan = "cd_2000", adj = adj0)
attr(map, "existing_col") <- "cd_2000"

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
attr(map, "existing_col") <- "cd_2000"

map <- map %>%
  mutate(
    uid = row_number(),
    ndv = coalesce(ndv, 0),
    nrv = coalesce(nrv, 0)
  )
attr(map, "existing_col") <- "cd_2000"

counties_south <- paste0("06", c("037","071","059","065","073","025"))
counties_bay   <- paste0("06", c("001","013","039","047","053","067","069",
                                 "075","077","081","085","087","095","099","113"))

# build clean submaps 
# South
south_sf  <- dplyr::filter(map_sf, county %in% counties_south)
adj_south <- redist.adjacency(south_sf)
map_south <- redist_map(south_sf, ndists = 30, pop_tol = 0.005, adj = adj_south)
attr(map_south, "existing_col") <- NULL
if ("cd_2000" %in% names(map_south)) map_south[["cd_2000"]] <- NULL

# Bay
bay_sf  <- dplyr::filter(map_sf, county %in% counties_bay)
adj_bay <- redist.adjacency(bay_sf)
map_bay <- redist_map(bay_sf, ndists = 15, pop_tol = 0.005, adj = adj_bay)
attr(map_bay, "existing_col") <- NULL
if ("cd_2000" %in% names(map_bay)) map_bay[["cd_2000"]] <- NULL

# cluster flag
map <- map %>%
  mutate(cluster = case_when(county %in% counties_bay ~ "Bay",
                             county %in% counties_south ~ "South",
                             TRUE ~ "Remainder"))
attr(map, "existing_col") <- "cd_2000"

# Add an analysis name attribute
attr(map, "analysis_name") <- "CA_2000"

map$state <- "CA"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CA_2000/CA_cd_2000_map.rds", compress = "xz")
cli_process_done()
