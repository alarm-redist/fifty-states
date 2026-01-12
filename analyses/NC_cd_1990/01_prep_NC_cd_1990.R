###############################################################################
# Download and prepare data for `NC_cd_1990` analysis
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
cli_process_start("Downloading files for {.pkg NC_cd_1990}")

path_data <- download_redistricting_file("NC", "data-raw/NC", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NC_1990/shp_vtd.rds"
perim_path <- "data-out/NC_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NC} shapefile")
    # read in redistricting data
    nc_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        join_vtd_shapefile(year = 1990) |>
        st_transform(EPSG$NC)

    nc_shp <- nc_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nc_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nc_shp <- rmapshaper::ms_simplify(nc_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    nc_shp$adj <- redist.adjacency(nc_shp)

    # TODO any custom adjacency graph edits here

    write_rds(nc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NC} shapefile")
}
