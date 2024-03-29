###############################################################################
# Download and prepare data for `MT_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MT_cd_2020}")

path_data <- download_redistricting_file("MT", "data-raw/MT")

url <- "https://redistricting.lls.edu/wp-content/uploads/mt_2020_congress_2021-11-12_2031-06-30.zip"
path_enacted <- "data-raw/MT/MT_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "MT_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/MT/MT_enacted/mt_2020_congress_2021-11-12_2031-06-30.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MT_2020/shp_vtd.rds"
perim_path <- "data-out/MT_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MT} shapefile")
    # read in redistricting data
    mt_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MT)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MT", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MT"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MT", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MT"), vtd),
            cd_2010 = as.integer(cd))
    mt_shp <- left_join(mt_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    cd_shp <- st_read(here(path_enacted))
    mt_shp <- mt_shp %>%
        mutate(cd_2020 = geo_match(mt_shp, cd_shp, method = "area"),
            .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = mt_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mt_shp <- rmapshaper::ms_simplify(mt_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mt_shp$adj <- redist.adjacency(mt_shp)

    mt_shp <- mt_shp %>%
        fix_geo_assignment(muni)

    write_rds(mt_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mt_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MT} shapefile")
}
