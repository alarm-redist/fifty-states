###############################################################################
# Set up redistricting simulation for `IL_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IL_cd_2020}")

map <- redist_map(il_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = il_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "IL_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IL_2020/IL_cd_2020_map.rds", compress = "xz")
cli_process_done()
