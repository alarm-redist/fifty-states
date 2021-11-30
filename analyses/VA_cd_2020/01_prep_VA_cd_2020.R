###############################################################################
# Download and prepare data for `VA_cd_2020` analysis
# © ALARM Project, October 2021
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
cli_process_start("Downloading files for {.pkg VA_cd_2020}")

path_data <- download_redistricting_file("VA", "data-raw/VA")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/VA_2020/shp_vtd.rds"
perim_path <- "data-out/VA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong VA} shapefile")
    # read in redistricting data
    va_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$VA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("VA", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("VA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("VA", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("VA"), vtd),
            cd_2010 = as.integer(cd))
    va_shp <- left_join(va_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = va_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        va_shp <- rmapshaper::ms_simplify(va_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    va_shp$adj <- redist.adjacency(va_shp)

    va_shp <- va_shp %>%
        fix_geo_assignment(muni)

    write_rds(va_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    va_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong VA} shapefile")
}