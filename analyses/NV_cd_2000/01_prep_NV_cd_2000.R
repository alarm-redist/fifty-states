###############################################################################
# Download and prepare data for `NV_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg NV_cd_2000}")

path_data <- download_redistricting_file("NV", "data-raw/NV", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NV_2000/shp_vtd.rds"
perim_path <- "data-out/NV_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NV} shapefile")
    # read in redistricting data
    nv_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$NV)

    nv_shp <- nv_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nv_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nv_shp <- rmapshaper::ms_simplify(nv_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nv_shp$adj <- redist.adjacency(nv_shp)

    nv_shp <- nv_shp %>%
        fix_geo_assignment(muni)

    write_rds(nv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NV} shapefile")
}
