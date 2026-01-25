###############################################################################
# Set up redistricting simulation for `AR_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AR_cd_2000}")

map <- redist_map(ar_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = ar_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "AR_2000"

map$state <- "AR"

# Add a stronger county constraint.
constr <- redist_constr(map)
constr <- add_constr_splits(constr, strength = 2, admin = county)

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AR_2000/AR_cd_2000_map.rds", compress = "xz")
cli_process_done()
