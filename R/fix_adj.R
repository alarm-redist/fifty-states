#' Modify geographic assignment for VTDs to avoid non-contiguities
#'
#' @param data A data frame
#' @param map_obj A redist_map object corresponding to `vtd_shp`. Used for adjacency matrix.
#' @param col The column of geographic information.
#'
#' @return An updated data frame with corrected geographic codes
#' @export
fix_geo_assignment <- function(data, col, adj = data$adj) {
  # get populations of geo units
  geo_pops <- data |>
    sf::st_drop_geometry() |>
    count({{ col }}, wt = pop, name = "pop")

  col_val <- rlang::eval_tidy(rlang::enquo(col), data)
  if (!is.character(col_val) && !is.factor(col_val) && !is.integer(col_val) &
      !is.numeric(col_val))
    cli::cli_abort("Column must be a {.cls character}, {.cls factor}, {.cls integer}, or {.cls numeric}.")
  if (is.character(col_val)) {
    col_type <- "chr"
    lev <- unique(col_val)
    col_val <- match(col_val, lev)
  } else if (is.factor(col_val)) {
    col_type <- "fct"
    lev <- levels(col_val)
    col_val <- as.integer(col_val)
  } else {
    col_type <- "int"
  }

  # map to internal function
  updated_geos <- purrr::map_int(.x = 1:nrow(data),
                                 .f = ~ assign_geo(.x, col_val, adj, col, geo_pops))

  if (col_type == "chr") {
    updated_geos <- lev[updated_geos]
  }
  if (col_type == "fct") {
    updated_geos <- factor(lev[updated_geos], levels = lev,
                           ordered = is.ordered(col_val))
  }
  data |>
    mutate({{ col }} := updated_geos)
}

#' Reassign geographic units to fix some common contiguity issues.
#'
#' @param i id number of the place
#' @param all_geos vector of geographic ids
#' @param adj adjacency matrix, from a redist_map object
#' @param col The column of geographic information
#' @param geo_pops A tibble of populations in each geographic unit
#'
#' @return A numeric object of the new geographic code,
#'
#' @keywords internal
assign_geo <- function(i, all_geos, adj, col, geo_pops) {
  # get neighbors and their geo units
  neighbors <- adj[[i]]
  neighbor_geo <- unique(all_geos[neighbors])

  # remove unmatched neighbor geos (all the negative ones)
  neighbor_assigned <- neighbor_geo[neighbor_geo > 0]

  # get geo unit of place
  place_geo <- all_geos[i]

  if (place_geo == -1) {
    # if not assigned to a place, don't change assignment
    return(place_geo)
  }

  if ((length(neighbor_assigned > 0)) && length(neighbor_geo) == 1 && (neighbor_geo[1] != place_geo)) {
    # check if any neighbors have assignment, and all have different assignment from place
    # if so, reassign
    return(neighbor_geo[1])
  }

  if (place_geo == -2) {
    # check if assignment was tied
    # if so, assign to place with highest population of neighbors
    return(
      geo_pops |>
        filter({{ col }} %in% neighbor_geo) |>
        filter(pop == max(pop)) |>
        pull({{ col }})
    )

  }

  # else return original location
  place_geo
}
