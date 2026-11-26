###############################################################################
# Set up redistricting simulation for `HI_cd_1990`
# © ALARM Project, September 2026
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg HI_cd_1990}")

map <- redist_map(
  hi_shp,
  pop_tol = 0.005,
  existing_plan = cd_1990,
  adj = hi_shp$adj
)

attr(map, "analysis_name") <- "HI_1990"

map$state <- "HI"

# Create a two-region sub-map for Honolulu County
hnl_rows <- which(map$county == "003")
newidx <- rep(NA_integer_, nrow(map))
newidx[hnl_rows] <- seq_along(hnl_rows) - 1L

# Drop self-neighbor entries from the Honolulu subgraph only.
adj_h <- lapply(hnl_rows, function(i) {
  nb <- newidx[as.integer(map$adj[[i]]) + 1L]
  as.integer(sort(nb[!is.na(nb) & nb != newidx[i]]))
})

# Rebuild the sub-map with relaxed population bounds
hnl_shp <- map[hnl_rows, ]
class(hnl_shp) <- setdiff(class(hnl_shp), "redist_map")
hnl_shp[[attr(map, "adj_col")]] <- NULL

map_honolulu <- redist_map(
  hnl_shp, existing_plan = NULL,
  total_pop = dplyr::all_of(attr(map, "pop_col")),
  ndists = 2L, nseats = 2L, seats_range = 1L,
  pop_tol = 1, adj = adj_h, planarize = FALSE
)

# Output the redist_map object. Do not edit this path.
write_rds(map, here("data-out/HI_1990/HI_cd_1990_map.rds"), compress = "xz")
cli_process_done()
