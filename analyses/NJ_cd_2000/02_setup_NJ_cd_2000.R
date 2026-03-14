###############################################################################
# Set up redistricting simulation for `NJ_cd_2000`
# © ALARM Project, March 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_cd_2000}")

map <- redist_map(nj_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = nj_shp$adj)

map <- map %>% merge_by(merge_group, drop_geom = FALSE)

# Extract merged geometry as sf
merged_sf <- sf::st_as_sf(map)

redistmetrics::prep_perims(
    shp = merged_sf,
    perim_path = here(perim_path)
) %>%
    invisible()

# Pseudo-county
map <- map %>%
    mutate(
        pseudo_county = pick_county_muni(
            map,
            counties = county,
            munis    = muni,
            pop_muni = get_target(map)
        )
    )

# Add an analysis name attribute
attr(map, "analysis_name") <- "NJ_2000"

map$state <- "NJ"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NJ_2000/NJ_cd_2000_map.rds", compress = "xz")
cli_process_done()
