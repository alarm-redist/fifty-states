###############################################################################
# Set up redistricting simulation for `WI_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg WI_cd_2020}")

map <- redist_map(wi_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = wi_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

# make cores
map <- map %>%
    mutate(core_id = redist.identify.cores(adj, cd_2010, boundary = 2),
        core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_2010)),
        core_id = if_else(is_county_split(core_id_lump, pseudo_county),
            str_c(pseudo_county, "_", core_id),
            as.character(core_id))) %>%
    select(-core_id_lump)

map_merge <- map %>%
    `attr<-`("existing_col", NULL) %>%
    merge_by(core_id, cd_2010, by_existing = FALSE)

# Add an analysis name attribute
attr(map, "analysis_name") <- "WI_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/WI_2020/WI_cd_2020_map.rds", compress = "xz")
cli_process_done()
