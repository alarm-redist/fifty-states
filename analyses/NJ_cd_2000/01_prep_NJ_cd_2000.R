###############################################################################
# Download and prepare data for NJ_cd_2000 analysis
# © ALARM Project, March 2026
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
cli_process_start("Downloading files for {.pkg NJ_cd_2000}")
path_data <- download_redistricting_file("NJ", "data-raw/NJ", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NJ_2000/shp_vtd.rds"
perim_path <- "data-out/NJ_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NJ} shapefile")
    # read in redistricting data
    nj_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$NJ)

    nj_shp <- nj_shp %>%
        rename(muni = place) %>%
        mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    redistmetrics::prep_perims(shp = nj_shp,
                             perim_path = here(perim_path)) |>
    invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nj_shp <- rmapshaper::ms_simplify(nj_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    nj_shp <- nj_shp %>%
        fix_geo_assignment(muni)

    # compute merge groups
    nj_shp$merge_group <- contiguity_merges(nj_shp)

    # create adjacency graph
    nj_shp$adj <- redist.adjacency(nj_shp)

    ###############################################################################
    # Logit-shift ndv/nrv
    ###############################################################################

    # Logit shift
    medsl_cty <- read_csv(
        here::here("data-raw/baseline_voteshare_medsl_00.csv"),
        show_col_types = FALSE
    )

    nj_shp <- nj_shp |>
        mutate(county_fips = stringr::str_sub(GEOID, 1, 5))

    nj_shp <- nj_shp |>
        group_by(county_fips) |>
        group_split() |>
        lapply(function(x) {
            meds <- medsl_cty |>
                filter(county == x$county_fips[1])

            target <- meds$dshare_00[1]

            if (length(target) == 0 || is.na(target)) return(x)

            logit_shift_baseline(
                x, 
                ndv = ndv, 
                nrv = nrv, 
                target = target,
                interval = c(-1.5, 1.5)
            )
        }) |>
        bind_rows()

    write_rds(nj_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nj_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NJ} shapefile")
}
