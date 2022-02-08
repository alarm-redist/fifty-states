###############################################################################
# Set up redistricting simulation for `TN_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg TN_cd_2020}")

cd_pop <- tn_shp %>% as_tibble() %>% count(cd_2020, wt = pop) %>% pull(n)
tol_existing <- max((cd_pop - mean(cd_pop)) / mean(cd_pop))

map <- redist_map(
    tn_shp,
    pop_tol = tol_existing,
    existing_plan = cd_2020,
    adj = tn_shp$adj)


# add muni county with top 20 munis
map <- map %>%
    mutate(pseudo_county = pick_county_muni(
        map,
        counties = county,
        munis = muni_name,
        pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "TN_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/TN_2020/TN_cd_2020_map.rds", compress = "xz")
cli_process_done()