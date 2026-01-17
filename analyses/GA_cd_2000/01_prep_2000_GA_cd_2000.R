###############################################################################
# Download and prepare data for `GA_cd_2000` analysis
# © ALARM Project, August 2025
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(baf)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg GA_cd_2000}")

path_data <- download_redistricting_file("GA", "data-raw/GA", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/GA_2000/shp_vtd.rds"
perim_path <- "data-out/GA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong GA} shapefile")
    # read in redistricting data
    ga_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$GA)

    ga_shp <- ga_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # eliminate empty shapes
    ga_shp <- ga_shp %>% filter(!st_is_empty(geometry))

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ga_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ga_shp <- rmapshaper::ms_simplify(ga_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ga_shp$adj <- redist.adjacency(ga_shp)

    ga_shp <- ga_shp %>%
        fix_geo_assignment(muni)

    write_rds(ga_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ga_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong GA} shapefile")
}
