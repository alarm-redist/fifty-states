###############################################################################
# Set up redistricting simulation for `HI_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_2010}")

map <- redist_map(hi_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = hi_shp$adj)

# Create sub-map for Honolulu County
map_honolulu <- map %>%
    filter(county == "003") %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

attr(map, "analysis_name") <- "HI_2010"

map$state <- "HI"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/HI_2010/HI_cd_2010_map.rds", compress = "xz")
cli_process_done()
