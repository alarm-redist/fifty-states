###############################################################################
# Download and prepare data for `MA_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MA_cd_2020}")

path_data <- download_redistricting_file("MA", "data-raw/MA")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MA_2020/shp_vtd.rds"
perim_path <- "data-out/MA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MA} shapefile")
    # read in redistricting data
    ma_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MA", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MA", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MA"), vtd),
            cd_2010 = as.integer(cd))
    ma_shp <- left_join(ma_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    dists <- read_sf("https://redistricting.lls.edu/wp-content/uploads/ma_2020_congress_2021-11-05_2031-06-30.json")

    ma_shp$cd_2020 <- as.integer(dists$Districts)[geo_match(from = ma_shp, to = dists, method = "area")]

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ma_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ma_shp <- rmapshaper::ms_simplify(ma_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ma_shp$adj <- redist.adjacency(ma_shp)

    ma_shp <- ma_shp %>%
        fix_geo_assignment(muni)

    write_rds(ma_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ma_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MA} shapefile")
}
