###############################################################################
# Set up redistricting simulation for `HI_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_1990}")

map <- redist_map(
  hi_shp,
  pop_tol = 0.005,
  existing_plan = cd_1990,   
  adj = hi_shp$adj
)

attr(map, "analysis_name") <- "HI_cd_1990"

map$state <- "HI"

# Output the redist_map object. Do not edit this path.
write_rds(map, here("data-out/HI_1990/HI_cd_1990_map.rds"), compress = "xz")
cli_process_done()
