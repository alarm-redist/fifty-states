###############################################################################
# Set up redistricting simulation for `NJ_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg NJ_cd_2000}")

map <- redist_map(nj_shp, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = nj_shp$adj)

# Pseudo-county
map <- map %>%
  mutate(
    pseudo_county = pick_county_muni(
      map,
      counties = county,   
      munis    = muni,     
      pop_muni = get_target(map)
    )
  )

# Add an analysis name attribute
attr(map, "analysis_name") <- "NJ_2000"

map$state <- "NJ"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/NJ_2000/NJ_cd_2000_map.rds", compress = "xz")
cli_process_done()

# Define helper function before it is called
check_valid <- function(pref_n, plans_matrix) {
  # ensure geometries are valid
  shp <- sf::st_make_valid(sf::st_as_sf(pref_n))
  
  # Build hybrid adjacency
  adj_orig  <- pref_n$adj
  adj_built <- redist::redist.adjacency(shp)  
  
  shp$.__uid <- seq_len(nrow(shp))
  poly_big <- shp |>
    sf::st_cast("POLYGON") |>
    dplyr::mutate(.area = sf::st_area(geometry)) |>
    dplyr::group_by(.__uid) |>
    dplyr::slice_max(.area, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(-.area) |>
    dplyr::arrange(.__uid)
  
  adj_poly <- redist::redist.adjacency(poly_big)
  
  adj_adjusted <- adj_built
  for (i in seq_along(adj_adjusted)) {
    if (length(adj_built[[i]]) > 0) {
      adj_adjusted[[i]] <- adj_poly[[i]]
    } else {
      adj_adjusted[[i]] <- adj_orig[[i]]  # fallback (islands)
    }
  }
  
  # Identify islands
  is_island <- vapply(adj_adjusted, length, 0L) == 0
  
  # Contiguity check
  checks <- vapply(seq_len(ncol(plans_matrix)), function(k) {
    p <- plans_matrix[, k]
    comp <- geomander::check_contiguity(adj_adjusted, p)$component
    
    by_district <- tapply(seq_along(p), p, function(idx) {
      idx_main <- idx[!is_island[idx]]
      if (length(idx_main) == 0) TRUE
      else max(comp[idx_main]) == 1
    })
    
    all(unlist(by_district))
  }, logical(1))
  
  return(list(valid = checks, adj_adjusted = adj_adjusted, is_island = is_island))
}
