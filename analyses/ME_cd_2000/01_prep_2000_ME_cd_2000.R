###############################################################################
# Download and prepare data for `ME_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg ME_cd_2000}")

path_data <- download_redistricting_file("ME", "data-raw/ME", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ME_2000/shp_vtd.rds"
perim_path <- "data-out/ME_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ME} shapefile")
    # read in redistricting data
    me_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$ME)

    me_shp <- me_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = me_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        me_shp <- rmapshaper::ms_simplify(me_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    me_shp$adj <- redist.adjacency(me_shp)

    me_shp <- me_shp %>%
        fix_geo_assignment(muni)

    write_rds(me_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    me_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ME} shapefile")
}
