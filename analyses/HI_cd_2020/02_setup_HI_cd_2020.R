###############################################################################
# Set up redistricting simulation for `HI_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_2020}")

map <- redist_map(hi_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = hi_shp$adj)

map_honolulu <- map %>%
    slice(-379) %>%
    filter(county == "Honolulu County") %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

# Add an analysis name attribute
attr(map, "analysis_name") <- "HI_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/HI_2020/HI_cd_2020_map.rds", compress = "xz")
cli_process_done()
