###############################################################################
# Set up redistricting simulation for `SC_cd_2020`
# © ALARM Project, April 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg SC_cd_2020}")


map <- sc_shp %>%
    mutate(pop_minoity = pop - pop_white,
           vap_minority = vap - vap_white) %>%
    redist_map(pop_tol = 0.005,
               existing_plan = cd_2020, adj = sc_shp$adj)

# TODO any filtering, cores, merging, etc.

map <- map %>%
    mutate(cores = make_cores(boundary = 3))

# Merge by both cores and county to preserve county contiguity
map_cores <- merge_by(map, cores, county)


# TODO remove if not necessary. Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
# map <- map %>%
#     mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
#                                             pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "SC_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/SC_2020/SC_cd_2020_map.rds", compress = "xz")
cli_process_done()
