###############################################################################
# Download and prepare data for `LA_cd_2010` analysis
# © ALARM Project, October 2022
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg LA_cd_2010}")

path_data <- download_redistricting_file("LA", "data-raw/LA", year = 2010)

# download the enacted plan.
url <- "https://house.louisiana.gov/h_redistricting2011/ShapfilesAnd2010CensusBlockEquivFiles/Shapefile%20-%20Congress%20-%20Act%202%20(HB6)%20of%20the%202011%20ES.zip"
path_enacted <- "data-raw/LA/LA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "LA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/LA/LA_enacted/Congress_-_Act_2_(2011).shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/LA_2010/shp_vtd.rds"
perim_path <- "data-out/LA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong LA} shapefile")
    # read in redistricting data
    la_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$LA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("LA", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("LA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("LA", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("LA"), vtd),
            cd_2000 = as.integer(cd))
    la_shp <- left_join(la_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    la_shp <- la_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(la_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = la_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        la_shp <- rmapshaper::ms_simplify(la_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    la_shp$adj <- redist.adjacency(la_shp)

    la_shp <- la_shp %>%
        fix_geo_assignment(muni)

    write_rds(la_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    la_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong LA} shapefile")
}
