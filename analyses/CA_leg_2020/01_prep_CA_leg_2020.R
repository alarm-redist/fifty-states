###############################################################################
# Download and prepare data for `CA_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg CA_leg_2020}")

path_data <- download_redistricting_file("CA", "data-raw/CA", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_2020/shp_vtd.rds"
perim_path <- "data-out/CA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CA} shapefile")
    # read in redistricting data
    ca_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$CA)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("CA", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("CA"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("CA", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("CA"), vtd),
                  ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("CA", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("CA"), vtd),
                  shd_2010 = as.integer(sldl))

    ca_shp <- ca_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    ca_shp <- ca_shp |>
        left_join(y = leg_from_baf(state = "CA"), by = "GEOID")


    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ca_shp,
                             perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ca_shp$adj <- adjacency(ca_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ca_shp$adj, ca_shp$ssd_2020)
    ccm(ca_shp$adj, ca_shp$shd_2020)

    ca_shp <- ca_shp |>
        fix_geo_assignment(muni)

    write_rds(ca_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ca_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CA} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(ca_shp, ca_shp$ssd_2020)
# redistio::draw(ca_shp, ca_shp$shd_2020)
