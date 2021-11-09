###############################################################################
# Set up redistricting simulation for `OR_cd_2020`
# © ALARM Project, October 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg OR_cd_2020}")

map <- redist_map(or_shp, pop_tol = 0.005, existing_plan = cd, adj = or_shp$adj) %>%
    mutate(pseudocounty = if_else(str_detect(county, "Multnomah"),
        county_muni, county))

# Add an analysis name attribute ----
attr(map, "analysis_name") <- "OR_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/OR_2020/OR_cd_2020_map.rds", compress = "xz")
cli_process_done()
