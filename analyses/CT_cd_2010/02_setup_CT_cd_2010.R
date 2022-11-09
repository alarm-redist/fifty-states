###############################################################################
# Set up redistricting simulation for `CT_cd_2010`
# © ALARM Project, November 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CT_cd_2010}")

map <- redist_map(ct_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ct_shp$adj)

# make pseudo counties with 40% of target size
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = 0.4*get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "CT_2010"

map$state <- "CT"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CT_2010/CT_cd_2010_map.rds", compress = "xz")
cli_process_done()
