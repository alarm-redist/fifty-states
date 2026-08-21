#' Find minimal precinct merges to resolve discontiguous precincts
#'
#' Some precincts consist of multiple discontiguous polygon pieces. When drawing
#' districts, these pieces might end up in different districts, creating
#' contiguity violations. This function identifies the minimal set of precinct
#' merges that ensure all pieces of every discontiguous precinct are connected
#' through merged precincts and thus forced into the same district.
#'
#' The algorithm works by:
#' 1. Identifying multipolygon precincts
#' 2. Flattening all geometries into individual polygon pieces and building
#'    a piece-level adjacency graph
#' 3. Converting the adjacency to an `igraph` object for fast BFS
#'    shortest-path computation
#' 4. For each discontiguous precinct, greedily connecting its pieces
#'    via shortest paths through the piece graph
#' 5. Collecting all precincts along those bridging paths as required
#'    merges, then resolving any additional merge requirements
#'
#' @param shp An `sf` object of precinct geometries (e.g., a `redist_map`).
#'
#' @return An integer vector of length `nrow(shp)` giving merge group IDs.
#'   Precincts sharing the same group ID must be kept in the same district.
#'   Precincts that need no merging receive their own unique group ID (their
#'   row index).
#'
#' @examples
#' nj <- alarmdata::alarm_50state_map('NJ')
#' merge_groups <- contiguity_merges(nj)
#' # precincts that must be merged together
#' table(merge_groups)[table(merge_groups) > 1]
#'
#' @concept contiguity
#'
#' @export
contiguity_merges <- function(shp) {
  rlang::check_installed('igraph')
  rlang::check_installed('geos')
  rlang::check_installed('wk')
  shp <- sf::st_as_sf(shp)
  n <- nrow(shp)

  # Convert to geos for fast geometry operations
  geo <- geos::as_geos_geometry(shp) |>
    geos::geos_make_valid()

  # Identify precincts with multiple sub-geometries (discontiguous pieces)
  n_sub <- geos::geos_num_geometries(geo)
  broken <- which(n_sub > 1)

  if (length(broken) == 0) {
    cli::cli_inform('No discontiguous precincts found.')
    return(seq_len(n))
  }

  cli::cli_inform('Found {length(broken)} discontiguous precinct{?s}.')

  # Flatten all geometries into individual polygon pieces, tracking precinct ownership
  piece_precinct <- rep(seq_len(n), times = n_sub)
  pieces_geo <- wk::wk_flatten(geo)
  n_pieces <- length(pieces_geo)

  # Build piece-level adjacency (0-indexed) using the fast geos-based builder
  adj_pieces <- geomander:::adj_geos(pieces_geo)

  # Convert to igraph edge list (1-indexed)
  el <- lapply(seq_len(n_pieces), function(i) {
    nbrs <- adj_pieces[[i]] + 1L # convert 0-indexed to 1-indexed
    nbrs <- nbrs[nbrs > i] # keep only upper-triangle to avoid duplicates
    if (length(nbrs) > 0) {
      cbind(i, nbrs)
    } else {
      NULL
    }
  }) |>
    do.call(rbind, args = _)

  if (is.null(el) || nrow(el) == 0) {
    cli::cli_warn('No adjacency edges found among polygon pieces. Returning identity groups.')
    return(seq_len(n))
  }

  g <- igraph::make_undirected_graph(as.vector(t(el)), n = n_pieces)

  # For each broken precinct, find the precincts needed to connect its pieces
  merge_list <- vector('list', length(broken))

  for (b in seq_along(broken)) {
    prec <- broken[b]
    my_pieces <- which(piece_precinct == prec)

    # Greedily grow a connected set of pieces via shortest paths
    reached <- my_pieces[1]
    unreached <- my_pieces[-1]
    all_path_pieces <- integer(0)

    while (length(unreached) > 0) {
      # Distance matrix from every reached piece to every unreached piece
      d <- igraph::distances(g, v = reached, to = unreached)

      if (all(is.infinite(d))) {
        cli::cli_warn(
          'Precinct {prec}: some pieces are completely disconnected (islands). Skipping.'
        )
        break
      }

      # Locate closest (reached, unreached) pair
      idx <- which.min(d)
      ri <- ((idx - 1) %% nrow(d)) + 1
      ci <- ((idx - 1) %/% nrow(d)) + 1

      from_piece <- reached[ri]
      to_piece <- unreached[ci]

      # Retrieve the actual shortest path
      sp <- igraph::shortest_paths(g, from = from_piece, to = to_piece)$vpath[[1]]
      path_nodes <- as.integer(sp)

      all_path_pieces <- c(all_path_pieces, path_nodes)
      reached <- unique(c(reached, path_nodes))
      unreached <- setdiff(unreached, reached)
    }

    # Map piece indices back to precinct IDs
    merge_list[[b]] <- unique(piece_precinct[unique(all_path_pieces)])
  }

  # Build merge groups, handling transitive merges
  group <- seq_len(n)

  for (merge_set in merge_list) {
    if (length(merge_set) > 1) {
      # Find every precinct already sharing a group with any member
      involved_groups <- unique(group[merge_set])
      all_involved <- which(group %in% involved_groups)
      target <- min(all_involved)
      group[all_involved] <- target
    }
  }

  group
}

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
#' # TODO
check_plans_polygon_contiguity <- function(shp, plans) {
  if (inherits(plans, 'redist_plans')) {
    plans <- redist::get_plans_matrix(plans)
  }

  adj_orig <- redist::get_adj(shp)

  geo <- shp |>
    geos::as_geos_geometry() |>
    geos::geos_make_valid()
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
