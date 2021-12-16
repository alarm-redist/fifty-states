###############################################################################
# Download and prepare data for `OK_cd_2020` analysis
# © ALARM Project, December 2021
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
cli_process_start("Downloading files for {.pkg OK_cd_2020}")

path_data <- download_redistricting_file("OK", "data-raw/OK")

# https://oksenate.gov/redistricting
path_enacted <- here("data-raw", "OK", "Congress Final 102621.shp")
if (!file.exists(path_enacted)) {
    url <- "https://oksenategov-my.sharepoint.com/personal/website_oksenate_gov/_layouts/15/download.aspx?UniqueId=1860110b%2D0561%2D4a92%2D8a9b%2Db2bebf6767f6"
    download(url, paste0(dirname(path_enacted), "/ok.zip"))
    unzip(paste0(dirname(path_enacted), "/ok.zip"), exdir = dirname(path_enacted))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OK_2020/shp_vtd.rds"
perim_path <- "data-out/OK_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OK} shapefile")
    # read in redistricting data
    ok_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$OK)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("OK", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("OK"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("OK", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("OK"), vtd),
            cd_2010 = as.integer(cd))
    ok_shp <- left_join(ok_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    dists <- read_sf(path_enacted)
    ok_shp$cd_2020 <- as.integer(dists$DISTRICT)[geo_match(from = ok_shp, to = dists, method = "area")]


    ok_shp <- ok_shp %>%
        mutate(across(contains(c("_16", "_18", "_20", "nrv", "ndv")), tidyr::replace_na, 0))

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ok_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ok_shp <- rmapshaper::ms_simplify(ok_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ok_shp$adj <- redist.adjacency(ok_shp)

    ok_shp <- ok_shp %>%
        fix_geo_assignment(muni)

    write_rds(ok_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ok_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OK} shapefile")
}
