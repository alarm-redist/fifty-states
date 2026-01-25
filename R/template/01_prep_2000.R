###############################################################################
# Download and prepare data for ```SLUG``` analysis
# ``COPYRIGHT``
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
cli_process_start("Downloading files for {.pkg ``SLUG``}")

path_data <- download_redistricting_file("``STATE``", "data-raw/``STATE``", year = ``YEAR``)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/``STATE``_``YEAR``/shp_vtd.rds"
perim_path <- "data-out/``STATE``_``YEAR``/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ``STATE``} shapefile")
    # read in redistricting data
    ``state``_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        join_vtd_shapefile(year = ``YEAR``) |>
        st_transform(EPSG$``STATE``)

    ``state``_shp <- ``state``_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_``OLDYEAR``, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ``state``_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ``state``_shp <- rmapshaper::ms_simplify(``state``_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ``state``_shp$adj <- redist.adjacency(``state``_shp)

    # TODO any custom adjacency graph edits here

    write_rds(``state``_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ``state``_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ``STATE``} shapefile")
}
