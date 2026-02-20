###############################################################################
# Download and prepare data for `MO_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg MO_cd_2000}")

path_data <- download_redistricting_file("MO", "data-raw/MO", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MO_2000/shp_vtd.rds"
perim_path <- "data-out/MO_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MO} shapefile")
    # read in redistricting data
    mo_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$MO)

    mo_shp <- mo_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mo_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mo_shp <- rmapshaper::ms_simplify(mo_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mo_shp$adj <- redist.adjacency(mo_shp)

    mo_shp <- mo_shp %>%
        fix_geo_assignment(muni)

    write_rds(mo_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mo_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MO} shapefile")
}
