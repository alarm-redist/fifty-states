###############################################################################
# Download and prepare data for `OH_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg OH_cd_2010}")

path_data <- download_redistricting_file("OH", "data-raw/OH", year = 2010)


cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OH_2010/shp_vtd.rds"
perim_path <- "data-out/OH_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OH} shapefile")
    # read in redistricting data
    oh_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$OH)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    d_cd <- make_from_baf("OH", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("OH"), vtd),
                  cd_2000 = as.integer(cd))

    # add municipalities

    geom_muni <- tigris::county_subdivisions(state="OH", year=2011)
    oh_shp$muni <- geom_muni$NAME[geomander::geo_match(oh_shp, geom_muni, method="area")] %>%
        na_if("County subdivisions not defined")

    oh_shp <- left_join(oh_shp, d_cd, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf('OH', from = read_baf_cd113('OH'), year = 2010) %>%
        rename(GEOID = vtd) %>% mutate(GEOID = paste0('39', GEOID))
    oh_shp <- oh_shp %>%
        left_join(baf_cd113, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = oh_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        oh_shp <- rmapshaper::ms_simplify(oh_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    oh_shp$adj <- redist.adjacency(oh_shp)

    oh_shp <- oh_shp %>%
        fix_geo_assignment(muni)

    write_rds(oh_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    oh_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OH} shapefile")
}
