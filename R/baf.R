#' Use a Block Assignment File to Create New Geographies
#'
#' @param state the state abbreviation
#' @param from either a character giving the type of Census unit to create, or a
#'   two-column data frame containing a BAF to work off of.
#' @param to the unit to create the column at. Defaults to `VTD`s
#' @param year the year, either 2020 (default) or 2010
#'
#' @return a data from of `to` units, with `from` columns added, ready to be joined
#' @export
make_from_baf <- function(state, from = "INCPLACE_CDP", to = "VTD", year = 2020) {
    if (year == 2020) {
        baf <- PL94171::pl_get_baf(state, cache_to = here(str_glue("data-raw/{state}/{state}_baf.rds")))
    } else {
        baf <- get_baf_10(state, cache_to = here(str_glue("data-raw/{state}/{state}_baf_10.rds")))
        if ('VTD' %in% names(baf)) {
            baf[['VTD']] <- baf[['VTD']] %>%
                mutate(DISTRICT = str_pad_l0(DISTRICT, 6))
        }
    }

    if (is.character(from)) {
        d_from <- baf[[from]]
    } else {
        d_from <- from
        from = names(from)[2]
    }
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


get_baf_10 <- function(state, geographies = NULL, cache_to = NULL, refresh = FALSE) {
  if (!is.null(cache_to) && file.exists(cache_to) && !refresh) {
    return(readRDS(cache_to))
  }

  fips <- censable::match_fips(state)
  abb <- censable::match_abb(state)

  zip_path <- tempfile(fileext = '.zip')
  zip_dir <- dirname(zip_path)
  base_name <- str_glue('BlockAssign_ST{fips}_{abb}')
  zip_url <- str_glue('https://www2.census.gov/geo/docs/maps-data/data/baf/{base_name}.zip')
  download(url = zip_url, path = zip_path)

  files <- utils::unzip(zip_path, list = TRUE)$Name
  utils::unzip(zip_path, exdir = zip_dir)
  out <- list()

  for (fname in files) {
    geogr <- str_match(fname, paste0(base_name, '_([A-Z_]+)\\.txt'))[, 2]
    if (!is.null(geographies) && !(geogr %in% geographies)) next
    table <- readr::read_delim(file.path(zip_dir, fname),
      delim = ',',
      col_types = readr::cols(.default = 'c'),
      progress = interactive(), lazy = FALSE
    )
    # check final column is not all NA
    if (!all(is.na(table[[ncol(table)]]))) {
      out[[geogr]] <- table
    }
  }

  if (!is.null(cache_to)) {
    saveRDS(out, file = cache_to, compress = 'gzip')
  }

  withr::deferred_clear()
  out
}

#' Download 2010 Block Assignment File to 113th Congressional Districts
#'
#' @return path to new zip directory, invisibly
#' @export
download_baf_cd113 <- function() {
    zip_dir <- fs::dir_create('data-raw/ZZ_baf_cd113')
    zip_url <- 'https://www2.census.gov/programs-surveys/decennial/rdo/mapping-files/2013/113-congressional-district-bef/cd113.zip'
    zip_path <- paste0(zip_dir, '/cd113.zip')
    download(url = zip_url, path = zip_path)
    utils::unzip(zip_path, exdir = zip_dir)
    invisible(zip_dir)
}


#' Use a Block Assignment File to Create New Geographies
#'
#' @param state the state abbreviation
#'
#' @return a tibble with block equivalency for 2010 block GEOIDs to CD113 (2013)
#' @export
read_baf_cd113 <- function(state) {
    if (!fs::dir_exists('data-raw/ZZ_baf_cd113')) {
        download_baf_cd113()
    }

    path <- stringr::str_glue('data-raw/ZZ_baf_cd113/{censable::match_fips(state)}_{censable::match_abb(state)}_CD113.txt')

    read_csv(
        path, col_types = c(BLOCKID = 'c', CD113 = 'i')
    ) %>%
        rename(
            cd_2010 = CD113
        )
}
