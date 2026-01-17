###############################################################################
# Download and prepare data for `MA_cd_1990` analysis
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
cli_process_start("Downloading files for {.pkg MA_cd_1990}")

path_data <- download_redistricting_file("MA", "data-raw/MA", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MA_1990/shp_vtd.rds"
perim_path <- "data-out/MA_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MA} shapefile")
    # read in redistricting data
    tract_path = "data-raw/MA/25_tracts.gpkg"
    raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
    raw_data$state = as.character(raw_data$state)
    shapefile <- st_read(tract_path, quiet = TRUE) |>
      rename(state_shp = state)
    ma_shp <- raw_data |>
      left_join(shapefile, by = "GEOID")
    # manually set state to MA
    ma_shp = mutate(ma_shp, state = "MA") |>
      st_as_sf()
    ma_shp = st_transform(ma_shp, EPSG$ID)

    ma_shp <- ma_shp |>
      mutate(county = coalesce(county.x, county.y)) |>
      select(-county.x, -county.y)

    ma_shp <- ma_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ma_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ma_shp <- rmapshaper::ms_simplify(ma_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ma_shp$adj <- redist.adjacency(ma_shp)

    write_rds(ma_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ma_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MA} shapefile")
}
