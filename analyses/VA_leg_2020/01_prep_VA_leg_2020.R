###############################################################################
# Download and prepare data for `VA_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg VA_leg_2020}")

path_data <- download_redistricting_file("VA", "data-raw/VA", year = 2020)

# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/VA_2020/shp_vtd.rds"
perim_path <- "data-out/VA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong VA} shapefile")
    # read in redistricting data
    va_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$VA)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("VA", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("VA"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("VA", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("VA"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("VA", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("VA"), vtd),
            shd_2010 = as.integer(sldl))

    va_shp <- va_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    va_shp <- va_shp |>
        left_join(y = leg_from_baf(state = "VA"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = va_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        va_shp <- rmapshaper::ms_simplify(va_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    va_shp$adj <- adjacency(va_shp)


    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(va_shp$adj, va_shp$ssd_2020)
    ccm(va_shp$adj, va_shp$shd_2020)

    va_shp <- va_shp |>
        fix_geo_assignment(muni)

    write_rds(va_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    va_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong VA} shapefile")
}

# visualize the enacted maps using:
redistio::draw(va_shp, va_shp$ssd_2020)
redistio::draw(va_shp, va_shp$shd_2020)
