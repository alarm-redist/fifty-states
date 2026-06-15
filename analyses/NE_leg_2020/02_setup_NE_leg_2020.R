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

# Add an analysis name attribute
attr(map_ssd, "analysis_name") <- "NE_SSD_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map_ssd, "data-out/NE_2020/NE_leg_2020_map_ssd.rds", compress = "xz")
cli_process_done()
