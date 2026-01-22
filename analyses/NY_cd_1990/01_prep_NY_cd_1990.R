###############################################################################
# Download and prepare data for `NY_cd_1990` analysis
# © ALARM Project, December 2025
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
cli_process_start("Downloading files for {.pkg NY_cd_1990}")

path_data <- download_redistricting_file("NY", "data-raw/NY", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NY_1990/shp_vtd.rds"
perim_path <- "data-out/NY_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NY} shapefile")
    # read in redistricting data
    ny_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        mutate(
            state  = as.character(state),
            county = as.character(county),
            tract  = as.character(tract)
        ) |>
        join_vtd_shapefile(year = 1990) |>
        st_transform(EPSG$NY)

    ny_shp <- ny_shp %>%
        rename(muni = place) %>%
        mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1980, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ny_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ny_shp <- rmapshaper::ms_simplify(ny_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ny_shp$adj <- redist.adjacency(ny_shp)

    # custom: fix muni
    ny_shp <- ny_shp %>%
        fix_geo_assignment(muni)

    # custom: fix two islands
    nbr <- geomander::suggest_neighbors(ny_shp, adj = ny_shp$adj)
    ny_shp$adj <- geomander::add_edge(ny_shp$adj, nbr$x, nbr$y)

    # add_edge <- function(adj, a, b) { adj[[a]] <- unique(as.integer(c(adj[[a]], b))); adj[[b]] <- unique(as.integer(c(adj[[b]], a))); adj }
    # ny_shp$adj <- add_edge(ny_shp$adj, 2393, 2394); ny_shp$adj <- add_edge(ny_shp$adj, 2617, 2616)

    write_rds(ny_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ny_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NY} shapefile")
}
