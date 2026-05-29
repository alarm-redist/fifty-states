###############################################################################
# Download and prepare data for `VA_cd_2000` analysis
# © ALARM Project, August 2025
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(baf)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg VA_cd_2000}")

path_data <- download_redistricting_file("VA", "data-raw/VA", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/VA_2000/shp_vtd.rds"
perim_path <- "data-out/VA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong VA} shapefile")
    # read in redistricting data
    va_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$VA)

    va_shp <- va_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # delete empty geom
    va_shp <- va_shp[!st_is_empty(va_shp), ]

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = va_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        va_shp <- rmapshaper::ms_simplify(va_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    va_shp$adj <- redist.adjacency(va_shp)

    va_shp <- va_shp %>%
        fix_geo_assignment(muni)

    write_rds(va_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    va_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong VA} shapefile")
}


###############################################################################
# Logit-shift ndv/nrv to match 2000 MEDSL county results
###############################################################################

#' Logit Shift Baseline Data
#'
#' @param d_baseline baseline data containing vote columns
#' @param ndv Unquoted Democratic vote column name
#' @param nrv Unquoted Republican vote column name
#' @param target target to logit shift to
#' @param tol
#'
#' @returns a data frame with adjusted vote columns
#' @export
#'
#' @examples
#' # TODO
logit_shift_baseline <- function(d_baseline, ndv, nrv,
                                 target = 0.5,
                                 tol = sqrt(.Machine$double.eps)) {
    if (missing(ndv) || missing(nrv)) {
        cli::cli_abort("Both {.arg ndv} and {.arg nrv} must be provided.")
    }
    ndv_q <- rlang::enquo(ndv)
    nrv_q <- rlang::enquo(nrv)

    ndv_vec <- dplyr::pull(d_baseline, !!ndv_q)
    nrv_vec <- dplyr::pull(d_baseline, !!nrv_q)

    turn <- ndv_vec + nrv_vec
    ldvs <- dplyr::if_else(turn > 0, log(ndv_vec) - log(nrv_vec), 0)

    res <- uniroot(function(shift) {
        stats::weighted.mean(plogis(ldvs + shift), turn) - target
    }, c(-1, 1), tol = tol)

    ldvs <- ldvs + res$root

    ndv_new <- turn*plogis(ldvs)
    nrv_new <- turn - ndv_new

    dplyr::mutate(
        d_baseline,
        !!rlang::as_name(ndv_q) := ndv_new,
        !!rlang::as_name(nrv_q) := nrv_new
    )
}

# 1. Load the MEDSL county CSV as `medsl_cty` ----
medsl_cty <- read_csv(
    here("data-raw/baseline_voteshare_medsl_00.csv"),
    show_col_types = FALSE
)

# 2. Add county_fips column based on VTD GEOID ----
va_shp <- va_shp |>
    mutate(county_fips = stringr::str_sub(GEOID, 1, 5))

names(va_shp)

# 3. For each county, logit-shift ndv/nrv to the 2000 target from MEDSL ----
va_shp |>
    group_by(county_fips) |>
    group_split() |>
    lapply(function(x) {
        meds <- medsl_cty |>
            filter(county == x$county_fips[1])
        target <- meds$dshare_00[1]

        x |>
            logit_shift_baseline(ndv = ndv, nrv = nrv, target = target)
    })
