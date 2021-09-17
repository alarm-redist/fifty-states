###############################################################################
# Set up redistricting simulation for ```SLUG```
# ``COPYRIGHT``
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg ``SLUG``}")

# TODO any pre-computation (usually not necessary)

map = redist_map(``state``_shp, pop_tol=0.005,
                 existing_plan=cd, adj=``state``_shp$adj)

# TODO any filtering, cores, merging, etc.

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-draft/``STATE``_``YEAR``/``SLUG``_map.rds", compress="xz")
cli_process_done()
