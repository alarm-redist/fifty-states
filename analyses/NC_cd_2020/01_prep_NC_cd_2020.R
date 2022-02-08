###############################################################################
# Download and prepare data for `NC_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NC_cd_2020}")

path_data <- download_redistricting_file("NC", "data-raw/NC")

path_enacted <- here("data-raw", "NC", "SL 2021-174 Congress.shp")
if (!file.exists(path_enacted)) {
    url <- "https://s3.amazonaws.com/dl.ncsbe.gov/ShapeFiles/USCongress/2021-11-04%20US_Congress_SL_2021-174.zip"
    download(url, paste0(dirname(path_enacted), "/nc.zip"))
    unzip(paste0(dirname(path_enacted), "/nc.zip"), exdir = dirname(path_enacted))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NC_2020/shp_vtd.rds"
perim_path <- "data-out/NC_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NC} shapefile")
    # read in redistricting data
    nc_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NC)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NC", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NC"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NC", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NC"), vtd),
            cd_2010 = as.integer(cd))
    nc_shp <- left_join(nc_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    dists <- read_sf(path_enacted)
    dists <- st_transform(dists, st_crs(nc_shp))
    nc_shp$cd_2020 <- as.integer(dists$DISTRICT)[geo_match(from = nc_shp, to = dists, method = "area")]

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nc_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nc_shp <- rmapshaper::ms_simplify(nc_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nc_shp$adj <- redist.adjacency(nc_shp)

    nc_shp <- nc_shp %>%
        fix_geo_assignment(muni)

    write_rds(nc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NC} shapefile")
}
