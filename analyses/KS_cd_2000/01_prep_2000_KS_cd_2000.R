###############################################################################
# Download and prepare data for `KS_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg KS_cd_2000}")

path_data <- download_redistricting_file("KS", "data-raw/KS", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KS_2000/shp_vtd.rds"
perim_path <- "data-out/KS_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong KS} shapefile")
    # read in redistricting data
    ks_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$KS)

    ks_shp <- ks_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ks_shp,
                               perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ks_shp <- rmapshaper::ms_simplify(ks_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ks_shp$adj <- redist.adjacency(ks_shp)

    # TODO any custom adjacency graph edits here

    ks_shp <- ks_shp %>%
        fix_geo_assignment(muni)

    write_rds(ks_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ks_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong KS} shapefile")
}
