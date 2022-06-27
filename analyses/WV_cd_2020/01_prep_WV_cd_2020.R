###############################################################################
# Download and prepare data for `WV_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg WV_cd_2020}")

path_data <- download_redistricting_file("WV", "data-raw/WV")

# https://www.wvlegislature.gov/redistricting.cfm
path_shp <- here("data-raw", "WV", "consensus_congressional.shp")
if (!file.exists(path_shp)) {
    url <- "https://www.wvlegislature.gov/legisdocs/redistricting/house/datafiles/consensus_congressional_shp.zip"
    download(url, paste0(dirname(path_shp), "/wv.zip"))
    unzip(paste0(dirname(path_shp), "/wv.zip"), exdir = dirname(path_shp))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WV_2020/shp_vtd.rds"
perim_path <- "data-out/WV_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WV} shapefile")

    # Custom Data Approach for WV ----
    # download precincts-with-results.geojson from https://github.com/TheUpshot/presidential-precinct-map-2020
    nyt <- geojsonsf::geojson_sf("data-raw/precincts-with-results.geojson") %>%
        mutate(state = str_sub(GEOID, 1, 2)) %>%
        filter(state == "54")
    nyt <- nyt %>%
        st_drop_geometry() %>%
        mutate(county = str_sub(GEOID, 3, 5)) %>%
        group_by(state, county) %>%
        summarize(pre_20_rep_tru = sum(votes_rep),
            pre_20_dem_bid = sum(votes_dem),
            .groups = "drop")  %>%
        mutate(ndv = pre_20_dem_bid, adv_20 = pre_20_dem_bid,
            nrv = pre_20_rep_tru, arv_20 = pre_20_rep_tru)

    wv_shp <- censable::build_dec("county", "WV") %>%
        censable::breakdown_geoid() %>%
        left_join(nyt, by = c("state", "county"))

    # read in redistricting data
    wv_shp <- wv_shp %>%
        st_transform(EPSG$WV)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_cd <- make_from_baf("WV", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("WV"), vtd),
            cd_2010 = as.integer(cd)) %>%
        mutate(state = str_sub(GEOID, 1, 2),
            county = str_sub(GEOID, 3, 5)) %>%
        select(state, county, cd_2010) %>%
        distinct()

    wv_shp <- wv_shp %>% left_join(d_cd, by = c("state", "county")) %>%
        relocate(cd_2010, .after = county)

    # Add enacted ----
    dists <- read_sf(path_shp)
    wv_shp <- wv_shp %>% mutate(
        cd_2020 = as.integer(dists$DISTRICT)[geo_match(from = wv_shp, to = dists, method = "area")],
        .after = cd_2010
    )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wv_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wv_shp <- rmapshaper::ms_simplify(wv_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wv_shp$adj <- redist.adjacency(wv_shp)

    wv_shp$state <- "WV"

    write_rds(wv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WV} shapefile")
}
