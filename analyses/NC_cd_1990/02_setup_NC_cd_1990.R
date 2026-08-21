###############################################################################
# Set up redistricting simulation for `NC_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NC_cd_1990}")

map <- redist_map(nc_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = nc_shp$adj)

# add cores
map <- mutate(map,
    core_id = redist.identify.cores(map$adj, map$cd_1990, boundary = 2),
    core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_1990)), # lump all non-core precincts in to "Other"
    core_id = if_else(as.logical(is_county_split(core_id_lump, county)), # break off counties which are split by core border
        str_c(county, "_", core_id),
        as.character(core_id))) %>%
    select(-core_id_lump)
map_cores <- merge_by(map, core_id)

# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "NC_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NC_1990/NC_cd_1990_map.rds", compress = "xz")
cli_process_done()
