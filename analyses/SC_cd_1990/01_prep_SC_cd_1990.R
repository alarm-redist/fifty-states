###############################################################################
# Download and prepare data for `SC_cd_1990` analysis
# © ALARM Project, January 2026
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
cli_process_start("Downloading files for {.pkg SC_cd_1990}")

path_data <- download_redistricting_file("SC", "data-raw/SC", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/SC_1990/shp_vtd.rds"
perim_path <- "data-out/SC_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong SC} shapefile")
    # read in redistricting data
    sc_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        mutate(
            state  = as.character(state),
            county = as.character(county),
            tract  = as.character(tract)
        ) |>
        join_vtd_shapefile(year = 1990) |>
        st_transform(EPSG$SC)

    sc_shp <- sc_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = sc_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        sc_shp <- rmapshaper::ms_simplify(sc_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    sc_shp$adj <- redist.adjacency(sc_shp)

    ###############################################################################
    # Logit-shift ndv/nrv to match 2000 MEDSL county results
    ###############################################################################

    # 1. Load the MEDSL county CSV as `medsl_cty` ----
    medsl_cty <- read_csv(
        here("data-raw/baseline_voteshare_medsl_00.csv"),
        show_col_types = FALSE
    )

    # 2. Add county_fips column based on VTD GEOID ----
    sc_shp <- sc_shp |>
        mutate(county_fips = stringr::str_sub(GEOID, 1, 5))

    names(sc_shp)

    # 3. For each county, logit-shift ndv/nrv to the 2000 target from MEDSL ----
    sc_shp <- sc_shp |>
        group_by(county_fips) |>
        group_split() |>
        lapply(function(x) {
            meds <- medsl_cty |>
                filter(county == x$county_fips[1])
            target <- meds$dshare_00[1]

            if (is.na(target)) return(x)

            logit_shift_baseline(x, ndv = ndv, nrv = nrv, target = target)
        }) |>
        bind_rows()


    ###############################################################################
    # Logit-shift ndv/nrv to match 1990 LEIP county results
    ###############################################################################

    # 1. Load the LEIP county CSV as `leip_cty` ----
    leip_cty <- read_csv(
      here("data-raw/baseline_voteshare_leip_92.csv"),
      show_col_types = FALSE
    )

    # 2. Add county_fips column based on VTD GEOID ----
    sc_shp <- sc_shp |>
      mutate(county_fips = stringr::str_sub(GEOID, 1, 5))

    names(sc_shp)

    # 3. For each county, logit-shift ndv/nrv to the 2000 target from MEDSL ----
    sc_shp <- sc_shp |>
      group_by(county_fips) |>
      group_split() |>
      lapply(function(x) {
        meds <- leip_cty |>
          filter(county == x$county_fips[1])
        target <- meds$dshare_92[1]

        if (is.na(target)) return(x)

        logit_shift_baseline(x, ndv = ndv, nrv = nrv, target = target)
      }) |>
      bind_rows()

    write_rds(sc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    sc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong SC} shapefile")
}
