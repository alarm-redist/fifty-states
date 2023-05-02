#' Finalize an analysis
#'
#' Upload produced maps and plans to the Dataverse, and create a summary page on
#' the ALARM website.
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#'
#' @returns nothing
finalize_analysis = function(state, type = "cd", year = 2020) {
    state <- str_to_upper(state)
    year <- as.character(as.integer(year))
    slug <- str_glue("{state}_{type}_{year}")

    # CHECK files
    path_map <- str_glue("data-out/{state}_{year}/{slug}_map.rds")
    path_plans <- str_glue("data-out/{state}_{year}/{slug}_plans.rds")
    path_stats <- str_glue("data-out/{state}_{year}/{slug}_stats.csv")
    if (!file.exists(here(path_map)))
        cli_abort(c("Map file missing for {.pkg {slug}}.",
                    "x" = "{.path {path_map}} not found."))
    if (!file.exists(here(path_plans)))
        cli_abort(c("Plans file missing for {.pkg {slug}}.",
                    "x" = "{.path {path_plans}} not found."))
    if (!file.exists(here(path_stats)))
        cli_abort(c("Summary statistics file missing for {.pkg {slug}}.",
                    "x" = "{.path {path_stats}} not found."))

    if (year == 2010) {
        # 2010 checks!
        cli::cli_progress_bar("Performing automatic checks", total = 8)
        # Map checks `n = 2` ----
        map_in <- readr::read_rds(path_map)
        warns <- FALSE

        # state column is state abb
        if (map_in$state[1] != censable::match_abb(map_in$state[1])) {
            cli::cli_warn('State column is not the state abbreviation in {.cls redist_map} object.')
            map_in$state <- censable::match_abb(map_in$state[1])
            warns <- TRUE
        }
        cli::cli_progress_update()

        # enacted column is `cd_2010`
        if (attr(map_in, 'existing_col') != 'cd_2010') {
            cli::cli_warn('Existing column is not {.val cd_2010}.')
            attr(map_in, 'existing_col') <- 'cd_2010'
            warns <- TRUE
        }
        cli::cli_progress_update()

        if (warns) {
            cli::cli_alert_warning('Updating {.cls redist_map} file.')
            readr::write_rds(map_in, path_map, compress = 'xz')
        }

        # Plans checks `n = 3` ----
        plans_in <- readr::read_rds(path_plans)

        # correct dimension for plans matrix
        if (ncol(get_plans_matrix(plans_in)) < 5001) { # allow for multiple `ref`? @cory thoughts, o.w. make !=
            cli::cli_abort('{.cls redist_plans} file for {state} contains the wrong number of columns in the plans matrix.')
        }
        cli::cli_progress_update()

        # plans has 5k sampled plans
        n_samp <- plans_in %>% redist::subset_sampled() %>% dplyr::pull(.data$draw) %>% dplyr::n_distinct()
        if (n_samp != 5000) {
            cli::cli_abort('{.cls redist_plans} file contains the wrong number of sampled plans.')
        }
        cli::cli_progress_update()

        # plans has the enacted plan
        if (!any(redist::subset_ref(plans_in)$draw == 'cd_2010')) {
            cli::cli_abort('{.cls redist_plans} file does not have {.val cd_2010} as a reference plan.')
        }
        cli::cli_progress_update()

        # Stats checks `n = 3` ----
        stats_in <- readr::read_csv(path_stats)
        warns <- FALSE

        # plans has no columns with .x suffix
        if (any(endsWith(names(stats), '.x'))) {
            # then fix!
            cols_to_fix <- names(stats)[endsWith(names(stats), '.x')]
            fixed <- stringr::str_sub(cols_to_fix, end = -3L)
            # if (length(fixed) != length(cols_to_fix)) {
            #     cli::cli_abort('{.val stats} file contains columns with `.x` but not corresponding columns.')
            # }

            for (col_i in seq_along(cols_to_fix)) {
                if (fixed[col_i] %in% names(stats_in)) {
                    stats_in <- stats_in %>%
                        dplyr::mutate(
                            {{fixed[col_i]}} := dplyr::coalesce({{fixed[col_i]}}, {{cols_to_fix[col_i]}})
                        ) %>%
                        dplyr::select(-dplyr::all_of(cols_to_fix[col_i]))
                } else {
                    stats_in <- stats_in %>%
                        rename({{fixed[col_i]}} := {{cols_to_fix[col_i]}})
                }
            }
            cli::cli_warn('{.val stats} file contains columns with `.x`.')
            warns <- TRUE
        }
        cli::cli_progress_update()

        # plans has no columns with .y suffix
        if (any(endsWith(names(stats), '.y'))) {
            # then fix!
            cols_to_fix <- names(stats)[endsWith(names(stats), '.y')]
            fixed <- stringr::str_sub(cols_to_fix, end = -3L)

            for (col_i in seq_along(cols_to_fix)) {
                if (fixed[col_i] %in% names(stats_in)) {
                    stats_in <- stats_in %>%
                        dplyr::mutate(
                            {{fixed[col_i]}} := dplyr::coalesce({{fixed[col_i]}}, {{cols_to_fix[col_i]}})
                        )
                } else {
                    stats_in <- stats_in %>%
                        rename({{fixed[col_i]}} := {{cols_to_fix[col_i]}})
                }
            }
            cli::cli_warn('{.val stats} file contains columns with `.y`.')
            warns <- TRUE
        }
        cli::cli_progress_update()


        # plans has no NAs
        if (any(is.na(stats_in))) {
            cli::cli_warn('{.val stats} file contains {.cls NA} values. Please verify that this is correct.')
        }

        if (warns) {
            cli::cli_alert_warning('Updating {.val stats} file.')
            readr::write_csv(stats_in, path_stats)
        }

        cli::cli_progress_done()
    } # end year 2010 checks

    cli_process_start("Uploading {.pkg {slug}} to the dataverse")
    pub_dataverse(slug, path_map, path_plans, path_stats)
    cli_process_done()
    cli_alert_info("Ask a maintainer to publish the dataverse updates.")

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
    doc2 <- read_lines(here("R/template/dataverse_addendum.md")) %>%
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
        existing <- dplyr::filter(dv_set$files, str_detect(filename, slug)) %>%
            dplyr::arrange(filename)
    } else {
        existing = data.frame()
    }

    if (nrow(existing) > 0)
        cli_abort("Files for {.pkg {slug}} already exist on the dataverse.")

    invisible(add_dataset_file(path_zip, dataset = dv_id, description = readable))
}

doc_render <- function(slug) {
    path_stage = file.path(tempdir(), slug)
    if (dir.exists(path_stage)) unlink(path_stage, recursive=TRUE)
    dir.create(path_stage)
    doc1 <- read_lines(here(str_glue("analyses/{slug}/doc_{slug}.md")))
    readable <- str_trim(str_sub(doc1[1], 2))
    doc2 <- read_lines(here("R/template/dataverse_addendum.md")) %>%
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
#' - creates a numbered map
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#' @param local are the files saved on your computer. Default is `FALSE`.
#'
#' @returns nothing, called for side effects
#' @export
quality_control <- function(state, type = "cd", year = 2020) {

    # there isn't a consistent figure name for the 2010/2020 map names, so just open the general page
    state_name <- censable::match_name(state)
    wiki_url <- stringr::str_glue(
        'https://en.wikipedia.org/wiki/{state_name}%27s_congressional_districts'
    )
    utils::browseURL(wiki_url)


}
