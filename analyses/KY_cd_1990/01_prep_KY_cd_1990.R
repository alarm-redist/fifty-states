###############################################################################
# Download and prepare data for `KY_cd_1990` analysis
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
cli_process_start("Downloading files for {.pkg KY_cd_1990}")

path_data <- download_redistricting_file("KY", "data-raw/KY", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KY_1990/shp_vtd.rds"
perim_path <- "data-out/KY_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong KY} shapefile")
    # read in redistricting data
    tract_path = "data-raw/KY/21_tracts.gpkg"
    raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
    raw_data$state = as.character(raw_data$state)
    shapefile <- st_read(tract_path, quiet = TRUE) |>
      rename(state_shp = state)
    ky_shp <- raw_data |>
      left_join(shapefile, by = "GEOID")
    # manually set state to KY
    ky_shp = mutate(ky_shp, state = "KY") |>
      st_as_sf()
    ky_shp = st_transform(ky_shp, EPSG$ID)

    ky_shp <- ky_shp |>
      mutate(county = coalesce(county.x, county.y)) |>
      select(-county.x, -county.y)

    ky_shp <- ky_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ky_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ky_shp <- rmapshaper::ms_simplify(ky_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ky_shp$adj <- redist.adjacency(ky_shp)

    write_rds(ky_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ky_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong KY} shapefile")
}

