#' Check contiguity of simulated plans
#'
#' Given a precinct-level `sf` object with an existing adjacency list and a
#' matrix of district assignments, this function builds a hybrid adjacency that
#' preserves special non-geometric connections and then tests each plan for
#' contiguity, treating true islands as automatically contiguous.
#'
#' @param shp sf object of cleaned, collated census data for a single state,
#'   with a list-column `adj` giving precinct adjacencies.
#' @param plans_matrix matrix of district assignments, typically the output of
#'   `redist::get_plans_matrix()` after running `redist_smc()`.
#'
#' @returns a logical vector with TRUE indicating contiguous plans
#'
#' @export
#' @examples
#' #TODO
check_plans_polygon_contiguity <- function(shp, plans) {

  if (inherits(plans, 'redist_plans')) {
    plans <- redist::get_plans_matrix(plans)
  }

  adj_orig  <- redist::get_adj(shp)

  geo <- shp |>
    as_geos_geometry() |>
    geos_make_valid()
  n_sub_geo <- geos::geos_num_geometries(geo)
  to_cast <- which(n_sub_geo > 1)

  if (length(to_cast) == 0) {
    # then the adjacency is necessarily correct: break early
    return(rep(TRUE, ncol(plans)))
  }

  adj_built <- geomander:::adj_geos(geo)

  for (i in seq_along(to_cast)) {
    areas <- geos::geos_area(wk::wk_flatten(geo[[to_cast[i]]]))
    geo[[to_cast[i]]] <- geos::geos_geometry_n(geo[[to_cast[i]]], which.max(areas))
  }

  # use the heavily optimized adjacency builder that takes a geos object
  adj_poly <- geomander:::adj_geos(geo)

  use_orig <- which(lengths(adj_orig) == 0)

  adj_adjusted <- adj_poly
  for (i in use_orig) {
    adj_adjusted[[i]] <- adj_orig[[i]]
  }

  geomander:::is_contiguous_mat(adj_adjusted, plans)
}
