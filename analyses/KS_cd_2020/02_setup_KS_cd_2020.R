###############################################################################
# Set up redistricting simulation for `KS_cd_2020`
# © ALARM Project, January 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg KS_cd_2020}")

map <- redist_map(ks_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ks_shp$adj)

map <- map %>%
    mutate(cores = make_cores(boundary = 2))
map_m <- merge_by(map, cores)

# Add an analysis name attribute
attr(map, "analysis_name") <- "KS_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/KS_2020/KS_cd_2020_map.rds", compress = "xz")
cli_process_done()
