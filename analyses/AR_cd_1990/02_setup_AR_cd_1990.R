###############################################################################
# Set up redistricting simulation for `AR_cd_1990`
# © ALARM Project, January 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg AR_cd_1990}")

map <- redist_map(ar_shp, pop_tol = 0.005,
                  existing_plan = cd_1990, adj = ar_shp$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "AR_1990"

# Add a stronger county constraint.
constr <- redist_constr(map)
constr <- add_constr_splits(constr, strength = 2, admin = county)

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/AR_1990/AR_cd_1990_map.rds", compress = "xz")
cli_process_done()
