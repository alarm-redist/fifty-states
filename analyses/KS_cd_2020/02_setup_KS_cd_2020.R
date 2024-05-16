###############################################################################
# Set up redistricting simulation for `KS_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg KS_cd_2020}")

map <- redist_map(ks_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ks_shp$adj)

map <- map %>%
    mutate(
        core_id = redist.identify.cores(map$adj, map$cd_2010, boundary = 2),
        core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_2010)), # lump all non-core precincts in to "Other"
        core_id = if_else(is_county_split(core_id_lump, county), # break off counties which are split by core border
            str_c(county, "_", core_id),
            as.character(core_id)),
        core_id = paste0(core_id, check_contiguity(map$adj, core_id)$component)
    ) %>%
    select(-core_id_lump)
map_m <- merge_by(map, core_id)

# Add an analysis name attribute
attr(map, "analysis_name") <- "KS_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/KS_2020/KS_cd_2020_map.rds", compress = "xz")
cli_process_done()
