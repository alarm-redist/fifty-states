#' Overwrite Large Counties with Municipalities
#'
#' @param map redist_map
#' @param counties larger geographic partition
#' @param munis smaller geographic partition
#' @param pop_muni population to use munis over counties
#'
#' @return map with new column `county_muni`
#' @export
#'
#' @examples
#' library(redist)
#' data(iowa)
#' ia <- redist_map(iowa, existing_plan = cd_2010, pop_tol = 0.01)
#' pick_county_muni(map, region, name)
pick_county_muni <- function(map, counties, munis, pop_muni = sum(map[[attr(map, 'pop_col')]])/attr(map, 'ndists')) {

    counties <- rlang::eval_tidy(rlang::enquo(counties), map)
    munis <- rlang::eval_tidy(rlang::enquo(munis), map)

    if (!inherits(map, 'redist_map')) {
        cli::cli_abort('`map` must be a `redist_map` object.')
    }

    pop <- map[[attr(map, 'pop_col')]]

    counties <- redist::redist.county.id(counties)
    munis <- redist::redist.county.id(munis)
    munis <- munis + max(counties)

    cty_pop <- tapply(pop, counties, sum)
    cty_pop <- cty_pop[cty_pop > pop_muni]

    counties[counties %in% names(cty_pop)] <- munis[counties %in% names(cty_pop)]

    dplyr::mutate(map, county_muni = redist::redist.county.id(counties))
}
