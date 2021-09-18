###############################################################################
# Set up redistricting simulation for `IA_cd_2020`
# © ALARM Project, September 2021
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg IA_cd_2020}")

map = redist_map(ia_shp, pop_tol = 0.0001,
    existing_plan = cd_2010, adj = ia_shp$adj)

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/IA_2020/IA_cd_2020_map.rds", compress = "xz")
cli_process_done()
