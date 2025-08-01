###############################################################################
# Download and prepare data for `IA_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg IA_cd_2000}")

path_data <- download_redistricting_file("IA", "data-raw/IA", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/IA_2000/shp_vtd.rds"
perim_path <- "data-out/IA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong IA} shapefile")
    # read in redistricting data
    ia_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$IA)

    ia_shp <- ia_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ia_shp,
                               perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ia_shp <- rmapshaper::ms_simplify(ia_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ia_shp$adj <- redist.adjacency(ia_shp)

    # TODO any custom adjacency graph edits here

    ia_shp <- ia_shp %>%
        fix_geo_assignment(muni)

    write_rds(ia_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ia_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong IA} shapefile")
}
