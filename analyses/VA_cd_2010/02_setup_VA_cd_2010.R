###############################################################################
# Set up redistricting simulation for `VA_cd_2010`
# © ALARM Project, October 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg VA_cd_2010}")

map <- redist_map(va_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = va_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)),
        state = "VA")
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "VA_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/VA_2010/VA_cd_2010_map.rds", compress = "xz")
cli_process_done()
