###############################################################################
# Download and prepare data for `SC_cd_2000` analysis
# © ALARM Project, July 2025
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
cli_process_start("Downloading files for {.pkg SC_cd_2000}")

path_data <- download_redistricting_file("SC", "data-raw/SC", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/SC_2000/shp_vtd.rds"
perim_path <- "data-out/SC_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong SC} shapefile")
    # read in redistricting data
    sc_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$SC)

    sc_shp <- sc_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = sc_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        sc_shp <- rmapshaper::ms_simplify(sc_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    sc_shp$adj <- redist.adjacency(sc_shp)

    sc_shp <- sc_shp %>%
        fix_geo_assignment(muni)

    write_rds(sc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    sc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong SC} shapefile")
}



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
sc_shp |>
    group_by(county_fips) |>
    group_split() |>
    lapply(function(x) {
        meds <- medsl_cty |>
            filter(county == x$county_fips[1])
        target <- meds$dshare_00[1]

        x |>
            logit_shift_baseline(ndv = ndv, nrv = nrv, target = target)
    })
