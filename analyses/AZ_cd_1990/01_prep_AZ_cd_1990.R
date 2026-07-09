###############################################################################
# Download and prepare data for `AZ_cd_1990` analysis
# © ALARM Project, December 2025
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
cli_process_start("Downloading files for {.pkg AZ_cd_1990}")

path_data <- download_redistricting_file("AZ", "data-raw/AZ", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AZ_1990/shp_vtd.rds"
perim_path <- "data-out/AZ_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AZ} shapefile")
    # read in redistricting data
    tract_path = "data-raw/AZ/04_tracts.gpkg"
    raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
    raw_data$state = as.character(raw_data$state)
    shapefile <- st_read(tract_path, quiet = TRUE) |>
      rename(state_shp = state)
    az_shp <- raw_data |>
      left_join(shapefile, by = "GEOID")
    # manually set state to AZ
    az_shp = mutate(az_shp, state = "AZ") |>
      st_as_sf()
    az_shp = st_transform(az_shp, EPSG$ID)

    az_shp <- az_shp |>
      mutate(county = coalesce(county.x, county.y)) |>
      select(-county.x, -county.y)

    az_shp <- az_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = az_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        az_shp <- rmapshaper::ms_simplify(az_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    az_shp$adj <- redist.adjacency(az_shp)

    # TODO any custom adjacency graph edits here

    write_rds(az_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    az_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AZ} shapefile")
}
