###############################################################################
# Download and prepare data for `NC_cd_2000` analysis
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
    library(tidyr)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NC_cd_2000}")

path_data <- download_redistricting_file("NC", "data-raw/NC", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NC_2000/shp_vtd.rds"
perim_path <- "data-out/NC_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NC} shapefile")
    # read in redistricting data
    nc_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$NC) %>%
        mutate(across(c(ndv, nrv), \(x) replace_na(x, 0)))

    nc_shp <- nc_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # delete empty geom
    nc_shp <- nc_shp[!st_is_empty(nc_shp), ]

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nc_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nc_shp <- rmapshaper::ms_simplify(nc_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nc_shp$adj <- redist.adjacency(nc_shp)

    nc_shp <- nc_shp %>%
        fix_geo_assignment(muni)

    ###############################################################################
    # Logit-shift ndv/nrv to match 2000 MEDSL county results
    ###############################################################################

    # 1. Load the MEDSL county CSV as `medsl_cty` ----
    medsl_cty <- read_csv(
        here::here("data-raw/baseline_voteshare_medsl_00.csv"),
        show_col_types = FALSE
    )

    # 2. Add county_fips column based on VTD GEOID ----
    nc_shp <- nc_shp |>
        mutate(county_fips = stringr::str_sub(GEOID, 1, 5))

    names(nc_shp)

    # 3. For each county, logit-shift ndv/nrv to the 2000 target from MEDSL ----
    nc_shp <- nc_shp |>
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

    write_rds(nc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NC} shapefile")
}
