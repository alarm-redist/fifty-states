###############################################################################
# Download and prepare data for `KY_cd_2010` analysis
# © ALARM Project, January 2023
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
cli_process_start("Downloading files for {.pkg KY_cd_2010}")

path_data <- download_redistricting_file("KY", "data-raw/KY", year = 2010, type = "block")

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/kentucky/>
url <- "https://redistricting.lls.edu/wp-content/uploads/ky_2010_congress_2012-02-10_2021-12-31.zip"
path_enacted <- "data-raw/KY/KY_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "KY_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/KY/KY_enacted/CH302C02.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KY_2010/shp_vtd.rds"
perim_path <- "data-out/KY_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong KY} shapefile")
    # read in redistricting data
    ky_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        left_join(y = tigris::blocks("KY", year = 2010), by = c("GEOID" = "GEOID10")) %>%
        st_as_sf() %>%
        st_transform(EPSG$KY)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("KY", "INCPLACE_CDP", "VTD", year = 2010) %>%
        mutate(GEOID = paste0(censable::match_fips("KY"), vtd)) %>%
        select(-vtd)
    # d_cd <- make_from_baf("KY", "CD", "VTD", year = 2010)  %>%
    #     transmute(GEOID = paste0(censable::match_fips("KY"), vtd),
    #               cd_2000 = as.integer(cd))
    # ky_shp <- left_join(ky_shp, d_muni, by = "GEOID") %>%
    #     left_join(d_cd, by="GEOID") %>%
    #     mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    #     relocate(muni, county_muni, cd_2000, .after = county)

    d_muni <- PL94171::pl_get_baf("KY", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_cd <- PL94171::pl_get_baf("KY", "CD")[[1]]  %>%
        transmute(GEOID = BLOCKID,
                  cd_2000 = as.integer(DISTRICT))
    ky_shp <- left_join(ky_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    ky_shp <- ky_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(ky_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ky_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ky_shp <- rmapshaper::ms_simplify(ky_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ky_shp$adj <- redist.adjacency(ky_shp)

    ky_shp <- ky_shp %>%
        fix_geo_assignment(muni)

    write_rds(ky_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ky_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong KY} shapefile")
}
