#' Load an ALARM Data map for a state analysis
#'
#' Pulls the published map from [alarmdata::alarm_50state_map()], writes it to
#' the repository's standard `data-out/ST_YEAR/ST_cd_YEAR_map.rds` location, and
#' assigns it as `map` in the sourcing environment. For 2020 congressional maps,
#' this also recreates the small derived objects that some simulation scripts
#' expect, such as `map_cores` or `map_2020`.
#'
#' @param state Two-letter state abbreviation.
#' @param year Analysis year.
#' @param analysis_type District type in the analysis slug. Defaults to `"cd"`.
#' @param repo Repository root. Defaults to [here::here()].
#' @param envir Environment where `map` and any derived objects should be
#'   assigned.
#' @param write_map Whether to write the map to `data-out`.
#' @param overwrite Whether an existing local map file should be overwritten.
#' @param retries Number of attempts to make when loading the published map.
#'   Useful for transient Dataverse or network failures.
#' @param retry_wait Seconds to wait between retries.
#'
#' @returns Invisibly, a list with the state, year, map path, and derived object
#'   names.
#' @export
load_alarmdata_map <- function(state,
                               year = 2020,
                               analysis_type = "cd",
                               repo = here::here(),
                               envir = parent.frame(),
                               write_map = TRUE,
                               overwrite = TRUE,
                               retries = as.integer(Sys.getenv("ALARMDATA_RETRIES", "3")),
                               retry_wait = as.numeric(Sys.getenv("ALARMDATA_RETRY_WAIT", "10"))) {
  if (!requireNamespace("alarmdata", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.pkg alarmdata} is required to load published ALARM maps.",
      "i" = "Install it or run with {.envvar MAP_SOURCE=prepared_map}, {.envvar MAP_SOURCE=prepared_shp}, or {.envvar MAP_SOURCE=prep}."
    ))
  }

  state <- toupper(state)
  year <- as.integer(year)
  retries <- suppressWarnings(as.integer(retries))
  if (length(retries) != 1L || is.na(retries) || retries < 1L) {
    retries <- 1L
  }
  retry_wait <- suppressWarnings(as.numeric(retry_wait))
  if (length(retry_wait) != 1L || is.na(retry_wait) || retry_wait < 0) {
    retry_wait <- 0
  }

  map <- NULL
  last_error <- NULL
  for (attempt in seq_len(retries)) {
    map <- tryCatch(
      alarmdata::alarm_50state_map(state = state, year = year),
      error = function(err) err
    )
    if (!inherits(map, "error")) {
      break
    }

    last_error <- map
    if (attempt < retries) {
      cli::cli_warn(c(
        "Could not load the published ALARM map for {state} {year} on attempt {attempt} of {retries}.",
        "i" = conditionMessage(last_error),
        "i" = "Retrying in {retry_wait} second{?s}."
      ))
      Sys.sleep(retry_wait)
    }
  }
  if (inherits(map, "error")) {
    cli::cli_abort(
      c(
        "Could not load the published ALARM map for {state} {year} after {retries} attempt{?s}.",
        "x" = conditionMessage(last_error)
      ),
      parent = last_error
    )
  }

  use_analysis_map(
    map = map,
    state = state,
    year = year,
    analysis_type = analysis_type,
    repo = repo,
    envir = envir,
    write_map = write_map,
    overwrite = overwrite
  )
}

use_analysis_map <- function(map,
                             state,
                             year,
                             analysis_type = "cd",
                             repo = here::here(),
                             envir = parent.frame(),
                             write_map = TRUE,
                             overwrite = TRUE) {
  state <- toupper(state)
  year <- as.integer(year)
  repo <- normalizePath(repo, mustWork = TRUE)
  output_dir <- file.path(repo, "data-out", paste0(state, "_", year))
  map_path <- file.path(
    output_dir,
    paste0(state, "_", analysis_type, "_", year, "_map.rds")
  )

  if (!inherits(map, "redist_map")) {
    cli::cli_abort("{.arg map} must inherit from {.cls redist_map}.")
  }

  attr(map, "analysis_name") <- paste0(state, "_", year)
  prepared <- prepare_alarmdata_2020_map(map, state = state, year = year)
  map <- prepared$map

  assign("map", map, envir = envir)
  for (nm in names(prepared$objects)) {
    assign(nm, prepared$objects[[nm]], envir = envir)
  }

  if (isTRUE(write_map)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    if (isTRUE(overwrite) || !file.exists(map_path)) {
      readr::write_rds(map, map_path, compress = "xz")
    }
  }

  invisible(list(
    state = state,
    year = year,
    map_path = map_path,
    derived = names(prepared$objects)
  ))
}

prepare_alarmdata_2020_map <- function(map, state, year) {
  state <- toupper(state)
  objects <- list()

  if (!identical(as.integer(year), 2020L)) {
    return(list(map = map, objects = objects))
  }

  map <- add_missing_alarmdata_pseudo_county(map, state)

  if (identical(state, "CA")) {
    map <- map %>%
      dplyr::mutate(
        dplyr::across(
          dplyr::contains(c("_16", "_18", "_20")),
          \(x) dplyr::coalesce(x, 0)
        ),
        ndv = dplyr::coalesce(.data$ndv, 0),
        nrv = dplyr::coalesce(.data$nrv, 0)
      )
  }

  if (identical(state, "KS")) {
    map <- ensure_core_id(
      map,
      plan_col = "cd_2010",
      split_counties = TRUE,
      add_components = TRUE
    )
    objects$map_m <- redist::merge_by(map, core_id)
  }

  if (identical(state, "LA")) {
    if (!"core_id" %in% names(map)) {
      adj <- map$adj
      plan <- map$cd_2020
      map <- dplyr::mutate(
        map,
        core_id = redist::redist.identify.cores(adj, plan, boundary = 2)
      )
    }
    objects$map_m <- redist::merge_by(map, core_id)
  }

  if (identical(state, "NE")) {
    map <- ensure_core_id(
      map,
      plan_col = "cd_2010",
      split_counties = TRUE,
      add_components = FALSE
    )
    objects$map_cores <- redist::merge_by(map, core_id)
  }

  if (identical(state, "NM")) {
    if (!"cores" %in% names(map)) {
      map <- dplyr::mutate(map, cores = redist::make_cores(boundary = 2))
    }
    objects$map_cores <- redist::merge_by(map, cores, county)
  }

  if (identical(state, "OH")) {
    map <- ensure_oh_split_columns(map)
    objects$map_2020 <- make_oh_2020_map(map)
  }

  if (identical(state, "UT")) {
    if (!"cores" %in% names(map)) {
      map <- dplyr::mutate(map, cores = redist::make_cores(boundary = 2))
    }
    objects$map_merge <- redist::merge_by(
      map,
      cores,
      pseudo_county,
      drop_geom = FALSE
    )
  }

  list(map = map, objects = objects)
}

add_missing_alarmdata_pseudo_county <- function(map, state) {
  state <- toupper(state)

  if (identical(state, "OR")) {
    if ("pseudocounty" %in% names(map)) {
      return(map)
    }
    return(dplyr::mutate(
      map,
      pseudocounty = dplyr::if_else(
        stringr::str_detect(.data$county, "Multnomah"),
        .data$county_muni,
        .data$county
      )
    ))
  }

  if ("pseudo_county" %in% names(map)) {
    return(map)
  }

  states_using_pseudo_counties <- c(
    "AZ", "CA", "CO", "CT", "FL", "GA", "IL", "KY", "LA", "MA", "MI",
    "MN", "MT", "NC", "NJ", "NY", "OK", "PA", "TN", "TX", "UT", "VA",
    "WA", "WI"
  )

  if (!state %in% states_using_pseudo_counties) {
    return(map)
  }

  if (identical(state, "MI")) {
    return(dplyr::mutate(
      map,
      pseudo_county = dplyr::if_else(
        stringr::str_detect(.data$county, "(Wayne|Oakland|Macomb)"),
        .data$county_muni,
        .data$county
      )
    ))
  }

  if (identical(state, "TN")) {
    return(map %>%
      dplyr::mutate(
        pseudo_county = pick_county_muni(
          map,
          counties = county,
          munis = muni_name,
          pop_muni = redist::get_target(map)
        )
      ) %>%
      dplyr::select(-dplyr::matches("a(d|r)v_18")))
  }

  pop_muni <- switch(
    state,
    CT = 0.4 * redist::get_target(map),
    MN = 0.4 * redist::get_target(map),
    MT = 50e3,
    NJ = 0.4 * redist::get_target(map),
    redist::get_target(map)
  )

  dplyr::mutate(
    map,
    pseudo_county = pick_county_muni(
      map,
      counties = county,
      munis = muni,
      pop_muni = pop_muni
    )
  )
}

ensure_core_id <- function(map,
                           plan_col,
                           split_counties = TRUE,
                           add_components = FALSE) {
  if ("core_id" %in% names(map)) {
    return(map)
  }

  plan <- map[[plan_col]]
  adj <- map$adj
  map <- map %>%
    dplyr::mutate(
      core_id = redist::redist.identify.cores(adj, plan, boundary = 2),
      core_id_lump = forcats::fct_lump_n(
        as.character(.data$core_id),
        max(plan, na.rm = TRUE)
      )
    )

  if (isTRUE(split_counties)) {
    map <- map %>%
      dplyr::mutate(
        core_id = dplyr::if_else(
          as.logical(redist::is_county_split(.data$core_id_lump, .data$county)),
          stringr::str_c(.data$county, "_", .data$core_id),
          as.character(.data$core_id)
        )
      )
  }

  if (isTRUE(add_components)) {
    component <- geomander::check_contiguity(map$adj, map$core_id)$component
    map <- map %>%
      dplyr::mutate(
        core_id = paste0(
          .data$core_id,
          component
        )
      )
  }

  dplyr::select(map, -dplyr::all_of("core_id_lump"))
}

ensure_oh_split_columns <- function(map) {
  needed <- c("merge_unit", "class_co", "class_muni")
  if (all(needed %in% names(map))) {
    return(map)
  }

  tgt_pop <- sum(map$pop) / 15

  oh_counties <- map %>%
    dplyr::as_tibble() %>%
    dplyr::group_by(.data$county) %>%
    dplyr::summarize(
      dplyr::across(dplyr::starts_with("pop"), sum),
      dplyr::across(
        dplyr::starts_with("cd_"),
        ~ dplyr::n_distinct(.x) > 1,
        .names = "split_{.col}"
      ),
      .groups = "drop"
    ) %>%
    dplyr::mutate(class_co = dplyr::if_else(.data$pop > tgt_pop, "more", "less")) %>%
    dplyr::select(
      dplyr::all_of(c("county", "pop", "class_co")),
      dplyr::starts_with("split_")
    )

  oh_munis <- map %>%
    dplyr::as_tibble() %>%
    dplyr::left_join(
      dplyr::select(oh_counties, dplyr::all_of(c("county", "class_co"))),
      by = "county"
    ) %>%
    dplyr::group_by(.data$county, .data$muni) %>%
    dplyr::summarize(
      dplyr::across(dplyr::starts_with("pop"), sum),
      dplyr::across(dplyr::starts_with("vap"), sum),
      class_co = .data$class_co[1],
      .groups = "drop_last"
    ) %>%
    dplyr::group_by(.data$county) %>%
    dplyr::transmute(
      muni = .data$muni,
      class_muni = dplyr::if_else(
        .data$class_co == "more",
        dplyr::case_when(
          .data$pop == max(.data$pop) & .data$pop > 100e3 & .data$pop < tgt_pop ~ "B(4)(b)",
          .data$pop >= tgt_pop ~ "B(4)(a)",
          TRUE ~ "none"
        ),
        "none"
      )
    ) %>%
    dplyr::ungroup()

  map %>%
    dplyr::left_join(dplyr::select(oh_counties, -dplyr::all_of("pop")), by = "county") %>%
    dplyr::left_join(oh_munis, by = c("muni", "county")) %>%
    dplyr::mutate(
      merge_unit = dplyr::case_when(
        !.data$split_cd_2020 ~ .data$county,
        .data$class_muni == "B(4)(b)" ~ .data$muni,
        TRUE ~ as.character(dplyr::row_number())
      )
    )
}

make_oh_2020_map <- function(map) {
  if (inherits(map, "sf")) {
    map <- sf::st_drop_geometry(map)
  }

  map %>%
    dplyr::group_by(.data$merge_unit, .data$county, .data$cd_2020) %>%
    dplyr::summarize(
      dplyr::across(dplyr::matches("(pop|vap)"), sum),
      muni = .data$muni[1],
      class_co = .data$class_co[1],
      class_muni = .data$class_muni[1],
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      split_unit = dplyr::if_else(.data$class_muni == "B(4)(a)", .data$muni, .data$county)
    )
}
