###############################################################################
# Download and prepare data for `TN_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg TN_cd_2000}")

path_data <- download_redistricting_file("TN", "data-raw/TN", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TN_2000/shp_vtd.rds"
perim_path <- "data-out/TN_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TN} shapefile")
    # read in redistricting data
    tn_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$TN)

    tn_shp <- tn_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = tn_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tn_shp <- rmapshaper::ms_simplify(tn_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    tn_shp$adj <- redist.adjacency(tn_shp)

    tn_shp <- tn_shp %>%
        fix_geo_assignment(muni)

    write_rds(tn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TN} shapefile")
}
