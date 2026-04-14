###############################################################################
# Set up redistricting simulation for `FL_cd_2000`
# © ALARM Project, April 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg FL_cd_2000}")

map <- redist_map(fl_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = fl_shp$adj)

# pseudo-county constraint
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "FL_2000"

map$state <- "FL"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/FL_2000/FL_cd_2000_map.rds", compress = "xz")
cli_process_done()
