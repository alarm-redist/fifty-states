###############################################################################
# Set up redistricting simulation for `TN_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TN_cd_2010}")

map <- redist_map(tn_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = tn_shp$adj)


# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni_name,
                                            pop_muni = get_target(map)))%>%
    select(-matches("a(d|r)v_18"))

# Add an analysis name attribute
attr(map, "analysis_name") <- "TN_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TN_2010/TN_cd_2010_map.rds", compress = "xz")
cli_process_done()
