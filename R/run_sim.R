#' Run an analysis simulation
#'
#' Loads the repository utilities, creates the local `data-out/ST_YEAR`
#' directory if needed, and sources the standard prep, setup, and simulation
#' scripts for a single analysis.
#'
#' @param analysis Analysis slug, e.g. `"FL_cd_2000"` or `"FL_cd_2020"`.
#' @param repo Repository root. Defaults to [here::here()].
#' @param load_all Whether to call [devtools::load_all()] before sourcing the
#'   analysis scripts.
#' @param dry_run If `TRUE`, report the paths that would be used without
#'   loading the package, creating directories, or sourcing scripts.
#' @param map_source Source for the analysis map. `"auto"` uses
#'   [alarmdata::alarm_50state_map()] for 2020 congressional analyses and
#'   otherwise falls back to the prep/setup scripts. `"alarmdata"` loads the
#'   published map and runs only `03_sim`; `"prepared_map"` reads the local map
#'   RDS and runs only `03_sim`; `"prepared_shp"` reads `shp_vtd.rds` and runs
#'   `02_setup` and `03_sim`; `"prep"` runs all three scripts.
#' @param skip_prep_if_ready If `TRUE`, skip the `01_prep` script when
#'   `data-out/ST_YEAR/shp_vtd.rds` already exists, and load that prepared
#'   shapefile into the standard `st_shp` object.
#' @param envir Environment used when sourcing the scripts. The same environment
#'   is used for all three scripts so objects created by prep are available to
#'   setup and simulation.
#'
#' @returns Invisibly, a list containing the analysis name, output directory, and
#'   sourced script paths.
#' @export
#'
#' @examples
#' \dontrun{
#' run_sim("FL_cd_2000")
#' run_sim("FL_cd_2020")
#' run_sim("FL_cd_2020", map_source = "alarmdata")
#'
#' # Check derived paths without running the scripts.
#' run_sim("FL_cd_2020", dry_run = TRUE)
#' }
run_sim <- function(analysis,
                    repo = here::here(),
                    load_all = TRUE,
                    dry_run = FALSE,
                    map_source = c("auto", "alarmdata", "prepared_map", "prepared_shp", "prep"),
                    skip_prep_if_ready = TRUE,
                    envir = parent.frame()) {
  if (!is.character(analysis) || length(analysis) != 1L ||
      is.na(analysis) || !nzchar(analysis)) {
    cli::cli_abort("{.arg analysis} must be a single analysis slug.")
  }

  map_source <- match.arg(map_source)

  match <- regexec("^([A-Za-z]{2})_([A-Za-z]+)_([0-9]{4})(?:_.*)?$", analysis)
  parts <- regmatches(analysis, match)[[1]]
  if (length(parts) != 4L) {
    cli::cli_abort(c(
      "{.arg analysis} must look like {.val ST_type_YEAR} with an optional suffix.",
      "i" = "Examples: {.val FL_cd_2000}, {.val FL_cd_2020}."
    ))
  }

  state <- toupper(parts[[2]])
  analysis_type <- parts[[3]]
  year <- parts[[4]]
  repo <- normalizePath(repo, mustWork = TRUE)
  analysis_dir <- file.path(repo, "analyses", analysis)
  output_dir <- file.path(repo, "data-out", paste0(state, "_", year))
  script_paths <- file.path(
    analysis_dir,
    paste0(c("01_prep_", "02_setup_", "03_sim_"), analysis, ".R")
  )
  prepared_shp <- file.path(output_dir, "shp_vtd.rds")
  prepared_map <- file.path(
    output_dir,
    paste0(state, "_", analysis_type, "_", year, "_map.rds")
  )

  if (!dir.exists(analysis_dir)) {
    cli::cli_abort("Analysis directory does not exist: {.file {analysis_dir}}")
  }

  missing <- script_paths[!file.exists(script_paths)]
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "Missing required analysis script{?s}:",
      setNames(as.list(missing), rep("x", length(missing)))
    ))
  }

  result <- list(
    analysis = analysis,
    state = state,
    analysis_type = analysis_type,
    year = year,
    analysis_dir = analysis_dir,
    output_dir = output_dir,
    prepared_shp = prepared_shp,
    prepared_map = prepared_map,
    map_source = map_source,
    scripts = script_paths
  )

  if (identical(map_source, "auto")) {
    map_source <- if (identical(year, "2020") && identical(analysis_type, "cd")) {
      "alarmdata"
    } else if (isTRUE(skip_prep_if_ready) && file.exists(prepared_shp)) {
      "prepared_shp"
    } else {
      "prep"
    }
    result$map_source <- map_source
  }

  if (isTRUE(dry_run)) {
    cli::cli_alert_info("Dry run for {.pkg {analysis}}")
    cli::cli_li("Analysis directory: {.file {analysis_dir}}")
    cli::cli_li("Output directory: {.file {output_dir}}")
    cli::cli_li("Map source: {.val {map_source}}")
    cli::cli_li("Map path: {.file {prepared_map}}")
    cli::cli_li("Scripts:")
    cli::cli_ul(scripts_for_map_source(script_paths, map_source))
    return(invisible(result))
  }

  old_wd <- setwd(repo)
  on.exit(setwd(old_wd), add = TRUE)

  if (isTRUE(load_all)) {
    cli::cli_alert_info("Loading repository utilities with {.fn devtools::load_all}")
    devtools::load_all(path = repo, quiet = TRUE)
  }

  ncores <- local_redist_smc_defaults(envir = envir)
  cli::cli_alert_info("Default {.fn redist_smc} cores: {ncores}")

  if (!"package:redist" %in% search()) {
    # Some custom constraints look up functions in the attached redist package.
    suppressPackageStartupMessages(library(redist))
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  cli::cli_alert_success("Output directory ready: {.file {output_dir}}")

  if (identical(map_source, "alarmdata")) {
    map_info <- load_alarmdata_map(
      state = state,
      year = year,
      analysis_type = analysis_type,
      repo = repo,
      envir = envir,
      write_map = TRUE,
      overwrite = TRUE
    )
    cli::cli_alert_success(
      "Loaded published {.cls redist_map} for {state} {year}; skipping prep and setup"
    )
    if (length(map_info$derived) > 0L) {
      cli::cli_alert_info(
        "Prepared setup object{?s}: {paste(map_info$derived, collapse = ', ')}"
      )
    }
    script_paths <- script_paths[3L]
  } else if (identical(map_source, "prepared_map")) {
    if (!file.exists(prepared_map)) {
      cli::cli_abort("Prepared map does not exist: {.file {prepared_map}}")
    }
    map_info <- use_analysis_map(
      map = readr::read_rds(prepared_map),
      state = state,
      year = year,
      analysis_type = analysis_type,
      repo = repo,
      envir = envir,
      write_map = FALSE
    )
    cli::cli_alert_success(
      "Loaded prepared {.cls redist_map} {.file {prepared_map}}; skipping prep and setup"
    )
    if (length(map_info$derived) > 0L) {
      cli::cli_alert_info(
        "Prepared setup object{?s}: {paste(map_info$derived, collapse = ', ')}"
      )
    }
    script_paths <- script_paths[3L]
  } else if (identical(map_source, "prepared_shp")) {
    if (!file.exists(prepared_shp)) {
      cli::cli_abort("Prepared shapefile does not exist: {.file {prepared_shp}}")
    }
    shp_name <- paste0(tolower(state), "_shp")
    assign(shp_name, readr::read_rds(prepared_shp), envir = envir)
    cli::cli_alert_success(
      "Loaded prepared shapefile {.file {prepared_shp}} as {.var {shp_name}}; skipping prep"
    )
    script_paths <- script_paths[-1L]
  } else if (!identical(map_source, "prep")) {
    cli::cli_abort("Unknown map source: {.val {map_source}}")
  }

  for (script in script_paths) {
    cli::cli_alert_info("Sourcing {.file {script}}")
    source(script, local = envir, chdir = FALSE)
  }

  cli::cli_alert_success("Finished {.pkg {analysis}}")
  invisible(result)
}

scripts_for_map_source <- function(script_paths, map_source) {
  if (map_source %in% c("alarmdata", "prepared_map")) {
    return(script_paths[3L])
  }
  if (identical(map_source, "prepared_shp")) {
    return(script_paths[-1L])
  }
  script_paths
}
