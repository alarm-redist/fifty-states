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
