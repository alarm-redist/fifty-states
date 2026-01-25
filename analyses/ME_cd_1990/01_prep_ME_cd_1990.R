###############################################################################
# Download and prepare data for `ME_cd_1990` analysis
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
cli_process_start("Downloading files for {.pkg ME_cd_1990}")

path_data <- download_redistricting_file("ME", "data-raw/ME", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ME_1990/shp_vtd.rds"
perim_path <- "data-out/ME_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ME} shapefile")
    # read in redistricting data
    me_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        mutate(state = as.character(state)) |> # FIX (ensures state is character variable across datasets)
        join_vtd_shapefile(year = 1990) |>
        st_transform(EPSG$ME)

    me_shp <- me_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = me_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        me_shp <- rmapshaper::ms_simplify(me_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    me_shp$adj <- redist.adjacency(me_shp)

    write_rds(me_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    me_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ME} shapefile")
}
