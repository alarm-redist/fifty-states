###############################################################################
# Download and prepare data for `NM_cd_2000` analysis
# © ALARM Project, July 2025
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
cli_process_start("Downloading files for {.pkg NM_cd_2000}")

path_data <- download_redistricting_file("NM", "data-raw/NM", year = 2000, overwrite=TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NM_2000/shp_vtd.rds"
perim_path <- "data-out/NM_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NM} shapefile")
    # read in redistricting data
    nm_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$NM)

    nm_shp <- nm_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nm_shp,
                               perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nm_shp <- rmapshaper::ms_simplify(nm_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nm_shp$adj <- redist.adjacency(nm_shp)

    nm_shp <- nm_shp %>%
        fix_geo_assignment(muni)

    write_rds(nm_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nm_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NM} shapefile")
}
