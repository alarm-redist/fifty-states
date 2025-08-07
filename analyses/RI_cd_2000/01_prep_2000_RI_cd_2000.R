###############################################################################
# Download and prepare data for `RI_cd_2000` analysis
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
cli_process_start("Downloading files for {.pkg RI_cd_2000}")

path_data <- download_redistricting_file("RI", "data-raw/RI", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/RI_2000/shp_vtd.rds"
perim_path <- "data-out/RI_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong RI} shapefile")
    # read in redistricting data
    ri_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        # TODO: If the state is not at the VTD-level, swap in a `tinytiger::tt_*` function
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$RI)

    ri_shp <- ri_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ri_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ri_shp <- rmapshaper::ms_simplify(ri_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # Create adjacency graph
    ri_shp$adj <- redist.adjacency(ri_shp)

    # Custom adjacency graph edit:
    # Connecting precinct 531 to precinct 523 (closest by distance)
    ri_shp$adj <- add_edge(
        redist.adjacency(ri_shp, ri_shp$cd_2000),
        v1 = 531,
        v2 = 523,
        zero = TRUE
    )

    ri_shp <- ri_shp %>%
        fix_geo_assignment(muni)

    write_rds(ri_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ri_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong RI} shapefile")
}
