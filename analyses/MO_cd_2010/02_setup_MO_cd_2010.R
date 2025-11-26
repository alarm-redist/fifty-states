###############################################################################
# Set up redistricting simulation for `MO_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MO_cd_2010}")

map <- redist_map(mo_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = mo_shp$adj)

# add cores
map <- mutate(map,
              core_id = redist.identify.cores(map$adj, map$cd_1990, boundary = 2),
              core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_1990)), # lump all non-core precincts in to "Other"
              core_id = if_else(as.logical(is_county_split(core_id_lump, county)), # break off counties which are split by core border
                                str_c(county, "_", core_id),
                                as.character(core_id))) %>%
  select(-core_id_lump)
map_cores <- merge_by(map, core_id)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MO_2010"
map$state <- "MO"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MO_2010/MO_cd_2010_map.rds", compress = "xz")
cli_process_done()
