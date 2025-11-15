#' Check contiguity of simulated plans
#'
#' Given a precinct-level \code{sf} object with an existing adjacency list and a
#' matrix of district assignments, this function builds a hybrid adjacency that
#' preserves special non-geometric connections and then tests each plan for
#' contiguity, treating true islands as automatically contiguous.
#'
#' @param pref_n sf object of cleaned, collated census data for a single state,
#'   with a list-column \code{adj} giving precinct adjacencies.
#' @param plans_matrix matrix of district assignments, typically the output of
#'   \code{redist::get_plans_matrix()} after running \code{redist_smc()}.
#'
#' @return A list with components:
#' \describe{
#'   \item{valid}{Logical vector indicating whether each plan is contiguous
#'     under the hybrid adjacency.}
#'   \item{adj_adjusted}{List of adjacency vectors used for the contiguity
#'     checks.}
#'   \item{is_island}{Logical vector indicating which precincts are treated
#'     as islands (no neighbors under the hybrid adjacency).}
#' }
#'
#' @concept filter_validated_plans
#'
#' @export

check_valid <- function(pref_n, plans_matrix) {
  # ensure geometries are valid
  shp <- sf::st_make_valid(sf::st_as_sf(pref_n))
  
  # Build hybrid adjacency: use polygon-based rook adjacency where available,
  # but fall back to the original adjacency for units with only non-geometric neighbors
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
      adj_adjusted[[i]] <- adj_orig[[i]]  
    }
  }
  
  # Identify islands: units with no neighbors under the hybrid adjacency
  is_island <- vapply(adj_adjusted, length, 0L) == 0
  
  # Contiguity check: avoid falsely flagging islands as discontiguous
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
