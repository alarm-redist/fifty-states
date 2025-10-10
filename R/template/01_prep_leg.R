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
    library(cli)
    library(here)
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg ``SLUG``}")

path_data <- download_redistricting_file("``STATE``", "data-raw/``STATE``", year = ``YEAR``)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/``STATE``_``YEAR``/shp_vtd.rds"
perim_path <- "data-out/``STATE``_``YEAR``/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ``STATE``} shapefile")
    # read in redistricting data
    ``state``_shp <- read_csv(here(path_data), col_types = cols(GEOID``YR`` = "c")) |>
        join_vtd_shapefile(year = ``YEAR``) |>
        st_transform(EPSG$``STATE``)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("``STATE``", "INCPLACE_CDP", "VTD", year = ``YEAR``)  |>
        mutate(GEOID = paste0(censable::match_fips("``STATE``"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("``STATE``", "SLDU", "VTD", year = ``YEAR``)  |>
        transmute(GEOID = paste0(censable::match_fips("``STATE``"), vtd),
                  ssd_``OLDYEAR`` = as.integer(sldu))
    d_shd <- make_from_baf("``STATE``", "SLDL", "VTD", year = ``YEAR``)  |>
        transmute(GEOID = paste0(censable::match_fips("``STATE``"), vtd),
                  shd_``OLDYEAR`` = as.integer(sldl))

    ``state``_shp <- ``state``_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_``OLDYEAR``, .after = county) |>
        relocate(muni, county_muni, shd_``OLDYEAR``, .after = county)

    # add the enacted plan
    ``state``_shp <- ``state``_shp |>
        left_join(y = leg_from_baf(state = "``STATE``"), by = "GEOID")


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
    ``state``_shp$adj <- adjacency(``state``_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(``state``_shp$adj, ``state``_shp$ssd_2020)
    ccm(``state``_shp$adj, ``state``_shp$shd_2020)

    ``state``_shp <- ``state``_shp |>
        fix_geo_assignment(muni)

    write_rds(``state``_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ``state``_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ``STATE``} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(``state``_shp, ``state``_shp$ssd_2020)
# redistio::draw(``state``_shp, ``state``_shp$shd_2020)
