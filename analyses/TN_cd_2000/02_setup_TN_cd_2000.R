###############################################################################
# Set up redistricting simulation for `TN_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TN_cd_2000}")

map <- redist_map(tn_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = tn_shp$adj)

# Adjust pop_muni as needed to balance county/muni splits
# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))
# IF MERGING CORES OR OTHER UNITS:
# make a new `map_cores` object that is merged & used for simulating. You can set `drop_geom=TRUE` for this.

# Add an analysis name attribute
attr(map, "analysis_name") <- "TN_2000"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TN_2000/TN_cd_2000_map.rds", compress = "xz")
cli_process_done()
