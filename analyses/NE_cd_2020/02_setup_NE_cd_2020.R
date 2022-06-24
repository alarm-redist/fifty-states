###############################################################################
# Set up redistricting simulation for `NE_cd_2020`
# © ALARM Project, December 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NE_cd_2020}")

map <- redist_map(ne_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ne_shp$adj)

# add cores
map <- mutate(map,
    core_id = redist.identify.cores(map$adj, map$cd_2010, boundary = 2),
    core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_2010)), # lump all non-core precincts in to "Other"
    core_id = if_else(is_county_split(core_id_lump, county), # break off counties which are split by core border
        str_c(county, "_", core_id),
        as.character(core_id))) %>%
    select(-core_id_lump)
map_cores <- merge_by(map, core_id)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NE_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NE_2020/NE_cd_2020_map.rds", compress = "xz")
cli_process_done()
