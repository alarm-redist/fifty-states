###############################################################################
# Set up redistricting simulation for `ID_cd_1990`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ID_cd_1990}")

map <- redist_map(id_shp, pop_tol = 0.005,
    existing_plan = cd_1990, adj = id_shp$adj)

# make pseudo counties with default settings
map <- map |>
    mutate(pseudo_county = pick_county_muni(map, counties = county.x, munis = muni,
                                            pop_muni = get_target(map)))
map <- map %>%
  rename(county = county.x)
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "ID_1990"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/ID_1990/ID_cd_1990_map.rds", compress = "xz")
cli_process_done()
