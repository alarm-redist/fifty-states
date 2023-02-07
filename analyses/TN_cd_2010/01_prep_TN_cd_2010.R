###############################################################################
# Download and prepare data for `TN_cd_2010` analysis
# © ALARM Project, December 2022
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
cli_process_start("Downloading files for {.pkg TN_cd_2010}")

path_data <- download_redistricting_file("TN", "data-raw/TN", year = 2010)

# download the enacted plan.
url <- "https://opendata.arcgis.com/datasets/90e4742978674ef4aaf08eb9f9f845bb_2.zip"
path_enacted <- "data-raw/TN/TN_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "TN_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/TN/TN_enacted/TN_Congressional_Districts.shp"


cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TN_2010/shp_vtd.rds"
perim_path <- "data-out/TN_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TN} shapefile")
    # read in redistricting data
    tn_shp <- read_csv(here(path_data), col_types = cols(GEOID10 = "c")) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$TN)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("TN", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("TN"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("TN", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("TN"), vtd),
                  cd_2000 = as.integer(cd))
    tn_shp <- left_join(tn_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    tn_shp <- tn_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(tn_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = tn_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tn_shp <- rmapshaper::ms_simplify(tn_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    tn_shp$adj <- redist.adjacency(tn_shp)

    tn_shp <- tn_shp %>%
        fix_geo_assignment(muni)

    write_rds(tn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TN} shapefile")
}
