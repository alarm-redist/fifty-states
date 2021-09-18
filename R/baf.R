#' Use a Block Assignment File to Create New Geographies
#'
#' @param state the state abbreviation
#' @param from either a character giving the type of Census unit to create, or a
#'   two-column data frame containing a BAF to work off of.
#' @param to the unit to create the column at. Defaults to `VTD`s
#'
#' @return a data from of `to` units, with `from` columns added, ready to be joined
#' @export
make_from_baf <- function(state, from = "INCPLACE_CDP", to = "VTD") {
    baf <- PL94171::pl_get_baf(state, cache_to = here(str_glue("data-raw/{state}/{state}_baf.rds")))
    if (is.character(from)) d_from <- baf[[from]]
    else d_from <- from
    d_to <- baf[[to]]
    if (is.null(from)) cli_abort("{.arg from} not found in {state} BAF.")
    if (is.null(to)) cli_abort("{.arg to} not found in {state} BAF.")

    state_fp <- str_sub(d_to$BLOCKID[1], 1, 2)
    fmt_baf <- function(x, nm) {
        tidyr::unite(x, {{ nm }}, -BLOCKID, sep = "") %>%
            mutate({{ nm }} := na_if(.[[nm]], "NA"))
    }

    d_to <- fmt_baf(d_to, "to")
    d_from <- fmt_baf(d_from, "from")
    d <- left_join(d_to, d_from, by = "BLOCKID")
    d <- d %>%
        group_by(to) %>%
        summarize(from = names(which.max(table(from, useNA = "always"))))
    if (from == "INCPLACE_CDP") from <- "muni"
    to <- str_to_lower(to)
    from <- str_to_lower(from)
    rename(d, {{ to }} := to, {{ from }} := from)
}
