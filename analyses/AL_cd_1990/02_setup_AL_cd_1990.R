###############################################################################
# Set up redistricting simulation for `AL_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AL_cd_1990}")

map <- redist_map(al_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = al_shp$adj)

# add cores
map <- mutate(map,
              core_id = redist.identify.cores(map$adj, map$cd_1980, boundary = 2),
              core_id_lump = forcats::fct_lump_n(as.character(core_id), max(cd_1980)), # lump all non-core precincts in to "Other"
              core_id = if_else(as.logical(is_county_split(core_id_lump, county)), # break off counties which are split by core border
                                str_c(county, "_", core_id),
                                as.character(core_id))) %>%
  select(-core_id_lump)
map_cores <- merge_by(map, core_id)

# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "AL_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AL_1990/AL_cd_1990_map.rds", compress = "xz")
cli_process_done()
