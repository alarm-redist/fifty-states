###############################################################################
# Set up redistricting simulation for `NE_leg_2020`
# © ALARM Project, March 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NE_leg_2020}")

map_ssd <- redist_map(ne_shp, pop_tol = 0.05,
    existing_plan = ssd_2020, adj = ne_shp$adj)

# make pseudo counties with default settings
map_ssd <- map_ssd |>
    mutate(pseudo_county = pick_county_muni(map_ssd, counties = county, munis = muni,
        pop_muni = get_target(map_ssd)))

map_ssd <- mutate(map_ssd,
    core_id = redist.identify.cores(map_ssd$adj, map_ssd$ssd_2010, boundary = 2),
    core_id_lump = forcats::fct_lump_n(as.character(core_id), max(ssd_2010)), # lump all non-core precincts in to "Other"
    core_id = if_else(as.logical(is_county_split(core_id_lump, county)), # break off counties which are split by core border
        str_c(county, "_", core_id),
        as.character(core_id))) |>
    select(-core_id_lump)

# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.
map_cores <- merge_by(map_ssd, core_id, drop_geom = TRUE)

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "NE_SSD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/NE_2020/NE_leg_2020_map_ssd.rds", compress = "xz")
cli_process_done()
