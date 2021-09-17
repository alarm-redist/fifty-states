#' Modify geographic assignment for VTDs to avoid non-contiguities
#'
#' @param vtd_shp A shp file for a region, possibly generated from `create-vtd-template.R`
#' @param map_obj A redist_map object corresponding to `vtd_shp`. Used for adjacency matrix.
#' @param col_name The column of geographic information.
#'
#' @return A column vector with the reassigned geographic codes
#' @export
fix_geo_assignment <- function(vtd_shp, col_name) {
    # get populations of geo units
    geo_pops <- vtd_shp %>%
        st_drop_geometry() %>%
        count(!!as.name(col_name), wt = pop, name = "pop")

    # add row number to vtd_shp
    vtd_operate <- vtd_shp %>%
        mutate(id = row_number())

    # make adjacency matrix
    adj = redist.adjacency(vtd_shp)

    # map to internal function
    updated_geos <- map_dbl(.x = 1:nrow(vtd_shp),
        .f = ~ assign_geo(.x,
            all_geos = vtd_shp[[col_name]],
            adj = adj,
            col_name = col_name,
            geo_pops = geo_pops))

    return(updated_geos)
}

#' Reassign geographic units to fix some common contiguity issues.
#'
#' @param i id number of the place
#' @param all_geos vector of geographic ids
#' @param adj adjacency matrix, from a redist_map object
#' @param col_name The column of geographic information, must be a string
#' @param geo_pops A tibble of populations in each geographic unit
#'
#' @return A numeric object of the new geographic code,
#'
#' @keywords internal
assign_geo <- function(i, all_geos, adj, col_name, geo_pops) {
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
            geo_pops %>%
                filter(!!as.name(col_name) %in% neighbor_geo) %>%
                filter(pop == max(pop)) %>%
                pull(!!as.name(col_name))
        )

    }

    # else return original location
    return(place_geo)
}
