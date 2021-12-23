###############################################################################
# Download and prepare data for `AZ_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg AZ_cd_2020}")

path_data <- download_redistricting_file("AZ", "data-raw/AZ")

# download the enacted plan.
url <- "https://opendata.arcgis.com/api/v3/datasets/a979062526984bef89f7bb2717e8bad1_0/downloads/data?format=shp&spatialRefId=4326"
path_enacted <- "data-raw/AZ/AZ_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "AZ_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/AZ/AZ_enacted/CD_Test_Map_Version_13.9.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AZ_2020/shp_vtd.rds"
perim_path <- "data-out/AZ_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AZ} shapefile")
    # read in redistricting data
    az_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$AZ)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("AZ", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("AZ"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("AZ", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("AZ"), vtd),
                  cd_2010 = as.integer(cd))
    az_shp <- left_join(az_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    az_shp <- az_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(az_shp, cd_shp, method = "area")],
            .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = az_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        az_shp <- rmapshaper::ms_simplify(az_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    az_shp$adj <- redist.adjacency(az_shp)

    az_shp <- az_shp %>%
        fix_geo_assignment(muni)

    write_rds(az_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    az_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AZ} shapefile")
}

