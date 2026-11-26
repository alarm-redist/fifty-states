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

# Create a complete two-region Honolulu sub-map.
hnl_rows <- which(map$county == "003")
newidx <- rep(NA_integer_, nrow(map))
newidx[hnl_rows] <- seq_along(hnl_rows) - 1L

adj_h <- lapply(hnl_rows, function(i) {
    nb <- as.integer(map$adj[[i]]) + 1L
    nb <- nb[!is.na(newidx[nb])]
    as.integer(sort(newidx[nb]))
})

for (i in seq_along(adj_h)) {
    for (j in adj_h[[i]]) stopifnot((i - 1L) %in% adj_h[[j + 1L]])
}

d_h <- map[hnl_rows, ]
class(d_h) <- setdiff(class(d_h), "redist_map")
d_h[[attr(map, "adj_col")]] <- NULL

map_honolulu <- redist::redist_map(
    d_h,
    existing_plan = NULL,
    total_pop = dplyr::all_of(attr(map, "pop_col")),
    ndists = 2L, nseats = 2L, seats_range = 1L,
    pop_tol = 1,
    adj = adj_h,
    planarize = FALSE
)

stopifnot(
    nrow(map_honolulu) == length(hnl_rows),
    identical(map_honolulu$GEOID, map$GEOID[hnl_rows]),
    identical(
        map_honolulu[[attr(map_honolulu, "pop_col")]],
        map[[attr(map, "pop_col")]][hnl_rows]
    ),
    identical(lapply(map_honolulu$adj, as.integer), adj_h)
)

attr(map, "analysis_name") <- "HI_1990"

map$state <- "HI"

# Output the redist_map object. Do not edit this path.
write_rds(map, here("data-out/HI_1990/HI_cd_1990_map.rds"), compress = "xz")
cli_process_done()
