###############################################################################
# Download and prepare data for `MA_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg MA_cd_2010}")

path_data <- download_redistricting_file("MA", "data-raw/MA", year = 2010)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MA_2010/shp_vtd.rds"
perim_path <- "data-out/MA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MA} shapefile")
    # read in redistricting data
    ma_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$MA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    d_cd <- make_from_baf("MA", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("MA"), vtd),
                  cd_2000 = as.integer(cd))
    # add municipalities
    geom_muni <- tigris::county_subdivisions(state="MA", year=2011)
    ma_shp$muni <- geom_muni$NAME[geomander::geo_match(ma_shp, geom_muni, method="area")] %>%
        na_if("County subdivisions not defined")

    ma_shp <- left_join(ma_shp, d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf('MA', from = read_baf_cd113('MA'), year = 2010) %>%
        rename(GEOID = vtd) %>% mutate(GEOID = paste0('25', GEOID))
    ma_shp <- ma_shp %>%
        left_join(baf_cd113, by = "GEOID")

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
