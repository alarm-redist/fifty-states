#' Overwrite Large Counties with Municipalities
#'
#' Given a vector of county and municipality assignments,
#'
#' @param map redist_map
#' @param counties larger geographic partition, typically counties.
#' @param munis smaller geographic partition, typically municipalities.
#' @param pop_muni the population amount where the input to `counties` is
#' overwritten by the entries in munis if that population is greater for a county
#'
#' @return vector of new pseudo-county numeric ids
#' @export
#'
#' @examples
#' library(redist)
#' data(iowa)
#' ia <- redist_map(iowa, existing_plan = cd_2010, pop_tol = 0.01)
#' pick_county_muni(map = ia, counties = region, munis = name)
pick_county_muni <- function(map, counties, munis,
                             pop_muni = sum(map[[attr(map, 'pop_col')]])/attr(map, 'ndists')) {

    counties <- rlang::eval_tidy(rlang::enquo(counties), map)
    munis <- rlang::eval_tidy(rlang::enquo(munis), map)

    if (!inherits(map, 'redist_map')) {
        cli::cli_abort('`map` must be a `redist_map` object.')
    }

    pop <- map[[attr(map, 'pop_col')]]

    counties <- redist::redist.county.id(counties)
    munis[!is.na(munis)] <- redist::redist.county.id(munis[!is.na(munis)]) + max(counties)
    munis[is.na(munis)] <- counties[is.na(munis)]
    munis <- redist::redist.county.id(munis)


    cty_pop <- tapply(pop, counties, sum)
    cty_pop <- cty_pop[cty_pop > pop_muni]

    counties[counties %in% names(cty_pop)] <- munis[counties %in% names(cty_pop)]

    redist::redist.county.id(counties)
}
