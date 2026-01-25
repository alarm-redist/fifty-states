###############################################################################
# Set up redistricting simulation for `NH_cd_2000`
# © ALARM Project, November 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NH_cd_2000}")

# Run simulations at the MCD-level.
map <- redist_map(nh_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = nh_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "NH_2000"

map$state <- "NH"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NH_2000/NH_cd_2000_map.rds", compress = "xz")
cli_process_done()
