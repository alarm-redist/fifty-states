#' Initialize a new analysis
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd` or `leg`.
#' @param year the analysis year
#' @param overwrite whether to overwrite an existing analysis
#'
#' @returns nothing
#' @export
#'
#' @examples
#' init_analysis('DE')
init_analysis <- function(state, type = "cd", year = 2020, overwrite = FALSE) {
  stopifnot(type %in% c('cd', 'leg'))
  state <- stringr::str_to_upper(state)
  year <- as.character(as.integer(year))
  slug <- stringr::str_glue("{state}_{type}_{year}")
  copyright <- format(Sys.Date(), "\u00A9 ALARM Project, %B %Y")

  path_r <- stringr::str_glue("analyses/{slug}/")
  if (dir.exists(path_r) & !overwrite) {
    cli::cli_abort("Analysis {.pkg {slug}} already exists.
                   Pass {.code overwrite=TRUE} to overwrite.")
  }
  dir.create(path_r, showWarnings = FALSE)
  cli::cli_alert_success("Creating {.file {path_r}}")
  path_data <- stringr::str_glue("data-out/{state}_{year}/")
  dir.create(path_data, showWarnings = FALSE)
  cli::cli_alert_success("Creating {.file {path_data}}")
  path_raw <- stringr::str_glue("data-raw/{state}/")
  dir.create(path_raw, showWarnings = FALSE)
  cli::cli_alert_success("Creating {.file {path_raw}}")

  templates <- Sys.glob(here("R/template/*.R"))
  if (year %in% c(1990, 2000)) {
    templates <- templates[!stringr::str_detect(templates, 'prep.R')]
  } else {
    templates <- templates[!stringr::str_detect(templates, 'prep_2000.R')]
  }
  if (type == 'leg') {
    templates <- templates[stringr::str_detect(templates, '_leg|_shd|_ssd')]
  } else {
    templates <- templates[!stringr::str_detect(templates, '_leg|_shd|_ssd')]
  }

  proc_template <- function(path) {
    if (stringr::str_detect(path, 'ssd')) {
      slug <- stringr::str_replace(slug, 'leg', 'ssd')
    } else if (stringr::str_detect(path, 'shd')) {
      slug <- stringr::str_replace(slug, 'leg', 'shd')
    }
    new_basename <- path |>
      basename() |>
      stringr::str_remove('_leg') |>
      stringr::str_replace(".R", stringr::str_c("_", slug, ".R"))
    if (stringr::str_detect(path, 'ssd|shd')) {
      new_basename <- new_basename |>
        stringr::str_remove(pattern = '_ssd') |>
        stringr::str_remove(pattern = '_shd')
    }

    new_path <- here(path_r, new_basename) |>
      stringr::str_replace('_2000_', '_')
    path |>
      readr::read_file() |>
      stringr::str_replace_all("``SLUG``", slug) |>
      stringr::str_replace_all("``STATE``", state) |>
      stringr::str_replace_all("``YEAR``", year) |>
      stringr::str_replace_all("``OLDYEAR``", as.character(as.integer(year) - 10L)) |>
      stringr::str_replace_all("``YR``", stringr::str_sub(year, 3)) |>
      stringr::str_replace_all("``state``", stringr::str_to_lower(state)) |>
      stringr::str_replace_all("``state_name``",
                               stringr::str_to_lower(state.name[state.abb == state])) |>
      stringr::str_replace_all("``COPYRIGHT``", copyright) |>
      readr::write_file(new_path)
    cli::cli_li("Creating {.file {path_r}{new_basename}}'")
    new_path
  }

  cli::cli_alert_info("Copying scripts from templates...")
  cli::cli_ul()
  new_paths <- purrr::map(templates, proc_template)
  cli::cli_end()

  doc_path <- stringr::str_c(path_r, "doc_", slug, ".md")
  template <-  here("R/template/documentation.md")
  if (type %in% c('leg', 'ssd', 'shd')) {
    template <- here("R/template/documentation_leg.md")
  }

  template |>
    readr::read_file() |>
    stringr::str_replace_all("``SLUG``", slug) |>
    stringr::str_replace_all("``STATE``", state) |>
    stringr::str_replace_all("``STATE NAME``", censable::match_name(state)) |>
    stringr::str_replace_all("``STATE``", state) |>
    stringr::str_replace_all("``YEAR``", year) |>
    stringr::str_replace_all("``TYPE``", stringr::str_c(
      c(cd = "Congressional",
        ssd = "State Senate",
        shd = "State House",
        leg = 'State House/Senate')[type],
      " Districts")
    ) |>
    stringr::str_replace_all("``state``", stringr::str_to_lower(state)) |>
    readr::write_file(here(doc_path))
  cli::cli_alert_success("Creating {.file {doc_path}}")

  cli::cli_alert_success("Initialization complete.")

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    purrr::map(new_paths, rstudioapi::navigateToFile)
    rstudioapi::navigateToFile(doc_path)
  }
  invisible(NULL)
}

#' Format code in line with the style guide
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#'
#' @returns nothing
enforce_style <- function(state, type = "cd", year = 2020) {
  state <- stringr::str_to_upper(state)
  year <- as.character(as.integer(year))
  slug <- stringr::str_glue("{state}_{type}_{year}")
  path_r <- stringr::str_glue("analyses/{slug}/")
  if (!dir.exists(path_r)) stop("Analysis `", slug, "` not found.")

  R_style <- function(...) {
    x <- styler::tidyverse_style(scope = "tokens",
                                 indent_by = 4,
                                 strict = FALSE,
                                 math_token_spacing = styler::specify_math_token_spacing(
                                   zero = c("'^'", "'*'", "'/'"),
                                   one = c("'+'", "'-'")))
    x
  }

  styler::cache_activate()
  styler::style_dir(here(path_r), style = R_style, exclude_dirs = "template")
}


# Imports for dev scripts
#' @import cli
#' @import dplyr
#' @import readr
#' @import stringr
#' @import redist
#' @importFrom here here
NULL
