###############################################################################
# Download and prepare data for `MO_leg_2020` analysis
# © ALARM Project, June 2026
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
cli_process_start("Downloading files for {.pkg MO_leg_2020}")

path_data <- download_redistricting_file("MO", "data-raw/MO", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MO_2020/shp_vtd.rds"
perim_path <- "data-out/MO_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MO} shapefile")
    # read in redistricting data
    mo_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$MO)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MO", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("MO"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("MO", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MO"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("MO", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MO"), vtd),
            shd_2010 = as.integer(sldl))

    mo_shp <- mo_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    mo_shp <- mo_shp |>
        left_join(y = leg_from_baf(state = "MO"), by = "GEOID")


    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mo_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mo_shp <- rmapshaper::ms_simplify(mo_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    mo_shp$adj <- adjacency(mo_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(mo_shp$adj, mo_shp$ssd_2020)
    ccm(mo_shp$adj, mo_shp$shd_2020)

    mo_shp <- mo_shp |>
        fix_geo_assignment(muni)

    write_rds(mo_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mo_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MO} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(mo_shp, mo_shp$ssd_2020)
# redistio::draw(mo_shp, mo_shp$shd_2020)
