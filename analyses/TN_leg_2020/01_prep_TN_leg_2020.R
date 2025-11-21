###############################################################################
# Download and prepare data for `TN_leg_2020` analysis
# © ALARM Project, November 2025
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
cli_process_start("Downloading files for {.pkg TN_leg_2020}")

path_data <- download_redistricting_file("TN", "data-raw/TN", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TN_2020/shp_vtd.rds"
perim_path <- "data-out/TN_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TN} shapefile")
    # read in redistricting data
    tn_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$TN)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("TN", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("TN"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("TN", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("TN"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("TN", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("TN"), vtd),
            shd_2010 = as.integer(sldl))

    tn_shp <- tn_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    tn_shp <- tn_shp |>
        left_join(y = leg_from_baf(state = "TN"), by = "GEOID")


    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = tn_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tn_shp <- rmapshaper::ms_simplify(tn_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    tn_shp$adj <- adjacency(tn_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(tn_shp$adj, tn_shp$ssd_2020)
    ccm(tn_shp$adj, tn_shp$shd_2020)

    tn_shp <- tn_shp |>
        fix_geo_assignment(muni)

    write_rds(tn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TN} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(tn_shp, tn_shp$ssd_2020)
# redistio::draw(tn_shp, tn_shp$shd_2020)
