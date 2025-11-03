###############################################################################
# Set up redistricting simulation for `MD_cd_2010`
# © ALARM Project, January 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_2010}")

# Remove state FIPS prefix (24) from cd_2010
md_shp <- md_shp %>%
  mutate(cd_2010 = as.integer(stringr::str_remove(cd_2010, "^24")))

map <- redist_map(md_shp, pop_tol = 0.005,
                  existing_plan = cd_2010, adj = md_shp$adj)

map <- map %>%
  mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                          pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MD_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MD_2010/MD_cd_2010_map.rds", compress = "xz")
cli_process_done()
