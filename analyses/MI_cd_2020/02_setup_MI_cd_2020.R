###############################################################################
# Set up redistricting simulation for `MI_cd_2020`
# © ALARM Project, October 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MI_cd_2020}")

map <- redist_map(mi_shp, pop_tol = 0.005,
                  ndists=13, adj = mi_shp$adj) %>%
    mutate(pseudocounty = if_else(str_detect(county, "(Wayne|Oakland|Macomb)"),
                                  county_muni, county))

# Add an analysis name attribute ----
attr(map, "analysis_name") <- "MI_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MI_2020/MI_cd_2020_map.rds", compress = "xz")
cli_process_done()
