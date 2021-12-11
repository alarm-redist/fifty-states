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
    # read in redistricting data
    wv_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$WV)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WV", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("WV"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("WV", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("WV"), vtd),
                  cd_2010 = as.integer(cd))
    wv_shp <- left_join(wv_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Add enacted ----
    dists <- read_sf(path_shp)
    wv_shp$cd_2020 <- as.integer(dists$DISTRICT)[geo_match(from = wv_shp, to = dists, method = "area")]

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = wv_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wv_shp <- rmapshaper::ms_simplify(wv_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wv_shp$adj <- redist.adjacency(wv_shp)

    # TODO any custom adjacency graph edits here

    wv_shp <- wv_shp %>%
        fix_geo_assignment(muni)

    write_rds(wv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WV} shapefile")
}

