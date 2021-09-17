#' Initialize a new analysis
#'
#' @param state the state abbreviation for the analysis, e.g. `WA`.
#' @param type the type of districts: `cd`, `ssd`, or `shd`.
#' @param year the analysis year
#' @param overwrite whether to overwrite an existing analysis
#'
#' @returns nothing
init_analysis = function(state, type="cd", year=2020, overwrite=F) {
    state = str_to_upper(state)
    year = as.character(as.integer(year))
    slug = str_glue("{state}_{type}_{year}")
    copyright = format(Sys.Date(), "\u00A9 ALARM Project, %B %Y")

    path_r <- str_glue("analyses/{slug}/")
    if (dir.exists(path_r) & !overwrite)
        stop("Analysis `", slug, "` already exists.\n",
             "  Pass `overwrite=TRUE` to overwrite.")
    dir.create(path_r, showWarnings=F)
    cli_alert_success("Creating {.file {path_r}}")
    dir.create(path_data <- str_glue("data-draft/{slug}/"), showWarnings=F)
    cli_alert_success("Creating {.file {path_data}}")
    dir.create(path_raw <- str_glue("data-raw/{state}/"), showWarnings=F)
    cli_alert_success("Creating {.file {path_raw}}")

    templates = Sys.glob(here("R/template/*.R"))

    proc_template = function(path) {
        new_basename = str_replace(basename(path), ".R", str_c("_", slug, ".R"))
        new_path = here(path_r, new_basename)
        read_file(path) %>%
            str_replace_all("``SLUG``", slug) %>%
            str_replace_all("``STATE``", state) %>%
            str_replace_all("``YEAR``", year) %>%
            str_replace_all("``state``", str_to_lower(state)) %>%
            str_replace_all("``COPYRIGHT``", copyright) %>%
            write_file(new_path)
        cli_li("Creating {.file {path_r}{new_basename}}'")
        new_path
    }

    cli_alert_info("Copying scripts from templates...")
    cli_ul()
    new_paths = purrr::map(templates, proc_template)
    cli_end()

    doc_path = str_c(path_r, "doc_", slug, ".md")
    usa = distinct(select(tigris::fips_codes, state, state_name))
    read_file(here("R/template/documentation.md")) %>%
            str_replace_all("``SLUG``", slug) %>%
            str_replace_all("``STATE``", state) %>%
            str_replace_all("``STATE NAME``", usa$state_name[usa$state == "IA"]) %>%
            str_replace_all("``STATE``", state) %>%
            str_replace_all("``YEAR``", year) %>%
            str_replace_all("``TYPE``", str_c(c(cd="Congressional", ssd="State Senate",
                                                shd="State House")[type], " Districts")) %>%
            str_replace_all("``state``", str_to_lower(state)) %>%
            write_file(here(doc_path))
    cli_alert_success("Creating {.file {doc_path}}")

    cli_alert_success("Initialization complete.")

    if (requireNamespace("rstudioapi", quietly=TRUE) && rstudioapi::isAvailable()) {
        purrr::map(new_paths, rstudioapi::navigateToFile)
        rstudioapi::navigateToFile(doc_path)
    }
    invisible(NULL)
}


# Imports for dev scripts
#' @import cli
#' @import dplyr
#' @import readr
#' @import stringr
#' @importFrom here here
NULL
