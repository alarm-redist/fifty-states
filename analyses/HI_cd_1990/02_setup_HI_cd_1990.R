###############################################################################
# Set up redistricting simulation for `HI_cd_1990`
# © ALARM Project, December 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_1990}")

# assumes `hi_shp` is in memory from your first script (or loaded from shp_path)
# and that `hi_shp$adj` exists.

map <- redist_map(
  hi_shp,
  pop_tol = 0.005,
  existing_plan = cd_1990,   
  adj = hi_shp$adj
)

# Create sub-map for Honolulu County (keep same pattern as HI_cd_2010)
map_honolulu <- map |>
  dplyr::filter(county == "003") |>
  `attr<-`("pop_bounds", attr(map, "pop_bounds"))

# REQUIRED for add_summary_stats() in your utilities
attr(map, "analysis_name") <- "HI_cd_1990"

map$state <- "HI"

# Output the redist_map object. Do not edit this path.
write_rds(map, here("data-out/HI_1990/HI_cd_1990_map.rds"), compress = "xz")
cli_process_done()
