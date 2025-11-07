#' Finalize an analysis
#'
#' Upload produced maps and plans to the Dataverse, and create a summary page on
#' the ALARM website.
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#' @param overwrite should automatic revisions be made and saved to files
#'
#' @returns nothing
#' @export
finalize_analysis = function(state, type = "cd", year = 2020, overwrite = TRUE) {
    withr::with_options(list(warn = 1), {


        state <- str_to_upper(state)
        year <- as.character(as.integer(year))
        slug <- str_glue("{state}_{type}_{year}")

        # CHECK files
        path_map <- str_glue("data-out/{state}_{year}/{slug}_map.rds")
        path_plans <- str_glue("data-out/{state}_{year}/{slug}_plans.rds")
        path_stats <- str_glue("data-out/{state}_{year}/{slug}_stats.csv")
        if (!file.exists(here(path_map))) {
            cli::cli_abort(c("Map file missing for {.pkg {slug}}.",
                        "x" = "{.path {path_map}} not found."))
        }

        if (!file.exists(here(path_plans))) {
            cli::cli_abort(c("Plans file missing for {.pkg {slug}}.",
                        "x" = "{.path {path_plans}} not found."))
        }
        if (!file.exists(here(path_stats))) {
            cli::cli_abort(c("Summary statistics file missing for {.pkg {slug}}.",
                        "x" = "{.path {path_stats}} not found."))
        }

        # 2010 checks!
        if (year == 2010) {
            cli::cli_progress_bar("Performing automatic checks", total = 6)
            # Map checks `n = 2` ----
            map_in <- readr::read_rds(path_map)
            warns <- FALSE

            # state column is state abb
            if (!"state" %in% names(map_in)) {
                cli::cli_warn("{.val state} column missing from {.cls redist_map}.")
                map_in$state <- censable::match_abb(state)
                map_in <- dplyr::relocate(map_in, "state", .after="GEOID")
                warns <- TRUE
            }
            if (map_in$state[1] != censable::match_abb(map_in$state[1])) {
                cli::cli_warn("State column is not the state abbreviation in {.cls redist_map}.")
                map_in$state <- censable::match_abb(map_in$state[1])
                warns <- TRUE
            }
            cli::cli_progress_update()

            # enacted column is `cd_2010`
            if (sum(c('cd_2020', "cd_2010", "cd_2000") %in% names(map_in)) != 2) {
                cli::cli_abort("{.val cd_2010} or {.val cd_2000} columns missing from {.cls redist_map}.")
            }
            if (attr(map_in, "existing_col") != "cd_2010") {
                cli::cli_warn("{.code attr(map, \"existing_col\")} is not {.val cd_2010}.")
                attr(map_in, "existing_col") <- "cd_2010"
                warns <- TRUE
            }
            if (warns && overwrite) {
                cli::cli_alert_warning("Updating {.cls redist_map} file.")
                readr::write_rds(map_in, path_map, compress = "xz")
            }
            cli::cli_progress_update()

            # Plans checks `n = 3` ----
            plans_in <- readr::read_rds(path_plans)
            warns <- FALSE

            # correct dimension for plans matrix
            if (ncol(get_plans_matrix(plans_in)) != 5001) {
                cli::cli_abort("{.cls redist_plans} for {state} contains the wrong number of sampled and/or reference plans.")
            }

            # plans has the enacted plan
            if (!any(redist::subset_ref(plans_in)$draw == "cd_2010")) {
                cli::cli_abort("{.cls redist_plans} does not have {.val cd_2010} as a reference plan.")
            }

            # plans has the right columns
            if (length(names(plans_in)) > 5)  {
                cli::cli_warn("{.cls redist_plans} has too many columns.")
                plans_in <- plans_in |>
                    dplyr::select(dplyr::any_of(c("draw", "district", "total_pop", "chain", 'pop_overlap')))
            }
            if (!all(c("draw", "district", "total_pop", "chain", 'pop_overlap') %in% names(plans_in))) {
                cli::cli_abort("{.cls redist_plans} is missing columns.")
            }
            cli::cli_progress_update()

            if (warns && overwrite) {
                cli::cli_alert_warning("Updating {.cls redist_plans} file.")
                readr::write_rds(plans_in, path_plans, compress = "xz")
            }
            cli::cli_progress_update()

            # Stats checks `n = 3` ----
            stats_in <- readr::read_csv(path_stats, show_col_types=FALSE)
            warns <- FALSE

            # plans has no columns with .x suffix
            if (any(endsWith(names(stats_in), ".x"))) {
                stats_in <- dplyr::select(stats_in, -ends_with(".x"))
                cli::cli_warn("{.val stats} file contains columns with `.x`.")
                warns <- TRUE
            }
            # plans has no columns with .y suffix
            if (any(endsWith(names(stats_in), ".y"))) {
                stats_in <- dplyr::rename_with(stats_in, function(x) stringr::str_sub(x, 1, -3), dplyr::ends_with(".y"))
                cli::cli_warn("{.val stats} file contains columns with `.y`.")
                warns <- TRUE
            }
            cli::cli_progress_update()

            map_cols <- setdiff(names(map_in)[map_in |>
                                                  dplyr::as_tibble() |>
                                                  tidyselect::eval_select(dplyr::starts_with(c(
                                                      'pop', 'vap', 'pre', 'uss', 'gov', 'atg', 'sos'
                                                  )), .)], c(
                                                      "GEOID", "state", "county", "muni", "county_muni", "cd_2010",
                                                      "cd_2020", "vtd", "pop", "vap", "area_land", "area_water", "adj",
                                                      "geometry", "pseudo_county")
            )
            exp_cols <- c("pop_overlap", "total_vap", "plan_dev", "comp_edge",
                          "comp_polsby", map_cols,
                          "ndshare", "e_dvs", "pr_dem", "e_dem", "pbias", "egap")
            if (!all(exp_cols %in% names(stats_in))) {
                cli::cli_abort("Missing the following column{?s} in {.cls redist_plans}:
                      {.arg {setdiff(exp_cols, names(stats_in))}}.")
            }
            if (!all(c("county_splits", "muni_splits") %in% names(stats_in))) {
                cli::cli_warn("Missing the following column{?s} in {.cls redist_plans}:
                      {.arg {setdiff(c('county_splits', 'muni_splits'), names(stats_in))}}.")
            }
            cli::cli_progress_update()

            # plans has no NAs
            nas <- vapply(stats_in, \(x) sum(is.na(x)), integer(1))
            if (sum(nas[-which(names(nas) == 'chain')] > 0)) {
                cli::cli_warn("{.val stats} file contains {.cls NA} values. Please verify that this is correct.")
            }

            if (warns && overwrite) {
                cli::cli_alert_warning("Updating {.val stats} file.")
                readr::write_csv(stats_in, path_stats)
            }

            cli::cli_progress_done()
        } # end year 2010 checks
    }) # end withr
    if (utils::askYesNo('After reading any warnings in the console, do you want to continue?')) {
        cli::cli_process_start("Uploading {.pkg {slug}} to the dataverse")
        pub_dataverse(slug, path_map, path_plans, path_stats)
        cli::cli_process_done()
        cli::cli_alert_info("Ask a maintainer to publish the dataverse updates.")
    } else {
        cli::cli_alert_info('Process manually aborted, please fix any problems and try again.')
    }

    invisible(TRUE)
}

pub_dataverse = function(slug, path_map, path_plans, path_stats) {
    library(dataverse)

    # SET UP zip
    path_stage = file.path(tempdir(), slug)
    if (dir.exists(path_stage)) unlink(path_stage, recursive=TRUE)
    dir.create(path_stage)
    file.copy(here(path_map), file.path(path_stage, basename(path_map)))
    file.copy(here(path_plans), file.path(path_stage, basename(path_plans)))
    file.copy(here(path_stats), file.path(path_stage, basename(path_stats)))

    doc1 <- read_lines(here(str_glue("analyses/{slug}/doc_{slug}.md")))
    readable <- str_trim(str_sub(doc1[1], 2))
    doc2 <- read_lines(here("R/template/dataverse_addendum.md")) |>
        str_replace_all("``SLUG``", slug)
    path_doc = file.path(path_stage, str_glue("{slug}_doc.md"))
    write_lines(c(doc1, "", doc2), path_doc)
    knitr::pandoc(path_doc, "html")
    file.remove(path_doc)

    path_zip <- file.path(tempdir(), paste0(slug, ".zip"))
    if (file.exists(path_zip)) file.remove(path_zip)
    cur_dir <- setwd(dirname(path_zip))
    zip(path_zip, slug, extras=str_glue("-x {slug}/.DS_Store"))
    setwd(cur_dir)

    dv_id <- "doi:10.7910/DVN/SLCD3E"
    dv_set <- get_dataset(dv_id)
    if (length(dv_set$files) > 0) {
        existing <- dplyr::filter(dv_set$files, str_detect(filename, slug)) |>
            dplyr::arrange(filename)
    } else {
        existing = data.frame()
    }

    if (nrow(existing) > 0)
        cli::cli_abort("Files for {.pkg {slug}} already exist on the dataverse.")

    invisible(add_dataset_file(path_zip, dataset = dv_id, description = readable))
}

doc_render <- function(slug) {
    path_stage = file.path(tempdir(), slug)
    if (dir.exists(path_stage)) unlink(path_stage, recursive=TRUE)
    dir.create(path_stage)
    doc1 <- read_lines(here(str_glue("analyses/{slug}/doc_{slug}.md")))
    readable <- str_trim(str_sub(doc1[1], 2))
    doc2 <- read_lines(here("R/template/dataverse_addendum.md")) |>
        str_replace_all("``SLUG``", slug)
    path_doc = file.path(path_stage, str_glue("{slug}_doc.md"))
    write_lines(c(doc1, "", doc2), path_doc)
    out <- knitr::pandoc(path_doc, "html")
    file.remove(path_doc)
    out
}

#' Quality Control for an analysis
#'
#' Assistant for running a manual quality control for an analysis.
#' This function:
#' - opens the wikipedia page for the state's congressional districts
#' - opens the All About Redistricting page for the state and decade's congressional plan
#' - creates a numbered map
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#' @param make_valid should it run `sf::st_make_valid()` on the map? Default is `FALSE`.
#' @param local are the files saved on your computer? Default is `FALSE`.
#'
#' @returns a ggplot of a numbered map
#' @export
quality_control <- function(state, type = "cd", year = 2020, make_valid = FALSE, local = FALSE) {

    # there isn't a consistent figure name for the 2010/2020 map names, so just open the general page
    state_name <- censable::match_name(state)
    wiki_url <- stringr::str_glue(
        'https://en.wikipedia.org/wiki/{state_name}%27s_congressional_districts'
    )
    utils::browseURL(wiki_url)

    aar_url <- stringr::str_glue(
        'https://redistricting.lls.edu/state/{stringr::str_replace(tools::toTitleCase(state_name), " ", "-")}/?cycle={year}&level=Congress'
    )
    utils::browseURL(aar_url)

    if (!local) {
        # also browse the github
        file_3_url <- stringr::str_glue(
            'https://github.com/alarm-redist/fifty-states/blob/main/analyses/{state}_cd_{year}/03_sim_{state}_cd_{year}.R'
        )
        utils::browseURL(file_3_url)
        file_doc_url <- stringr::str_glue(
            'https://github.com/alarm-redist/fifty-states/blob/main/analyses/{state}_cd_{year}/doc_{state}_cd_{year}.md'
        )
        utils::browseURL(file_doc_url)
    }

    if (!local) {
        if (!requireNamespace("alarmdata", quietly = TRUE)) {
            cli::cli_abort('{.pkg alarmdata} required for running QC when {.arg local} is {.val FALSE}.')
        }
        #plans <- alarmdata::alarm_50state_plans(state = state, year = year)
        map <- alarmdata::alarm_50state_map(state = state, year = year)
    } else {
        state <- stringr::str_to_upper(state)
        year <- as.character(as.integer(year))
        slug <- stringr::str_glue("{state}_{type}_{year}")
        path_map <- stringr::str_glue("data-out/{state}_{year}/{slug}_map.rds")
        map <- readr::read_rds(path_map)
    }
    if (make_valid) map <- sf::st_make_valid(map)
    p <- map |>
        dplyr::as_tibble() |>
        sf::st_as_sf() |>
        dplyr::group_by(dplyr::across(dplyr::all_of(paste0(type, '_', year)))) |>
        dplyr::summarise() |>
        ggplot2::ggplot(
            ggplot2::aes(
                label = .data[[paste0(type, '_', year)]],
                fill = stringr::str_pad(as.character(.data[[paste0(type, '_', year)]]), side = 'left', width = 2, pad = '0')
            )
        ) +
        ggplot2::geom_sf() +
        ggplot2::geom_sf_text() +
        ggplot2::labs(fill = 'district') +
        ggplot2::theme_void()

    p
}
