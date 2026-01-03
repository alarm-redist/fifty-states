###############################################################################
# Set up redistricting simulation for `HI_cd_2000`
# © ALARM Project, Janury 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_2000}")

map <- redist_map(hi_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = hi_shp$adj)

# Create sub-map for Honolulu County
map_honolulu <- map %>%
  filter(county == "003") %>%
  `attr<-`("pop_bounds", attr(map, "pop_bounds"))

attr(map, "analysis_name") <- "HI_2000"

map$state <- "HI"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/HI_2000/HI_cd_2000_map.rds", compress = "xz")
cli_process_done()
