#' Overwrite Large Counties with Municipalities
#'
#' Substantive geographic boundaries are sometimes municipalities within large
#' counties rather than the entire county. This function takes two geography
#' indicators and creates an unique identifier for the smaller subgeography,
#' when the size of the county is greater than one district (by default) or a manual
#' input to `pop_muni`. This tries to balance the goals of keeping both
#' municipalities and counties together without a more involved spanning-tree change.
#'
#' @param map redist_map
#' @param counties larger geographic partition, typically counties.
#' @param munis smaller geographic partition, typically municipalities.
#' @param pop_muni Integer. The population amount where the input to `counties` is
#' overwritten by the entries in munis if the county's population is larger than
#' this number. Default is the district size.
#'
#' @return vector of new pseudo-county numeric ids
#' @export
#'
#' @examples
#' library(redist)
#' data(iowa)
#' ia_map <- redist_map(iowa, existing_plan = cd_2010, pop_tol = 0.01)
#' pick_county_muni(map = ia_map, counties = region, munis = name)
pick_county_muni <- function(map, counties, munis, pop_muni = get_target(map)) {

    counties <- rlang::eval_tidy(rlang::enquo(counties), map)
    munis <- rlang::eval_tidy(rlang::enquo(munis), map)

    if (!inherits(map, 'redist_map')) {
        cli::cli_abort('`map` must be a `redist_map` object.')
    }

    pop <- map[[attr(map, 'pop_col')]]

    county_ids <- redist::redist.county.id(counties)
    munis[!is.na(munis)] <- redist::redist.county.id(munis[!is.na(munis)]) + max(county_ids)
    munis[is.na(munis)] <- county_ids[is.na(munis)]
    munis <- redist::redist.county.id(munis)


    cty_pop <- tapply(pop, county_ids, sum)
    cty_pop <- cty_pop[cty_pop > pop_muni]
    cty_exc = unique(counties)[as.integer(names(cty_pop))]
    cli::cli_alert_info("{?No counties//}{cty_exc} {?is/are} larger than the target population.")

    county_ids[county_ids %in% names(cty_pop)] <- munis[county_ids %in% names(cty_pop)]

    redist::redist.county.id(county_ids)
}
