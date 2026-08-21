###############################################################################
# Download and prepare data for `CA_leg_2020` analysis
# © ALARM Project, June 2026
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg CA_leg_2020}")

path_data <- download_redistricting_file("CA", "data-raw/CA", type = "block", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_2020/shp_vtd.rds"
perim_path <- "data-out/CA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CA} shapefile")

    # read in redistricting data
    ca_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        left_join(y = tigris::blocks("CA", year = 2020), by  = "GEOID20") |>
        sf::st_as_sf() |>
        st_transform(EPSG$CA)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- PL94171::pl_get_baf("CA", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)

    ca_shp <- left_join(ca_shp, d_muni, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, .after = county)

    ca_shp %>%
        mutate(tract = str_sub(GEOID, 1, 11)) %>%
        group_by(tract) %>%
        summarize(n_county_muni = n_distinct(county_muni)) %>%
        filter(n_county_muni > 1)

    # group by tract and summarize
    ca_shp <- ca_shp |>
        mutate(tract = str_sub(GEOID, 1, 11)) |>
        group_by(tract) |>
        summarize(
            muni = Mode(muni),
            state = unique(state),
            county = unique(county),
            county_muni = Mode(county_muni),
            across(where(is.numeric), sum)
        ) |>
        mutate(GEOID = tract)

    # add the enacted plan
    ca_shp <- ca_shp |>
        left_join(y = leg_from_baf(state = "CA", to = "tract"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ca_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ca_shp$adj <- adjacency(ca_shp)

    # custom adjacency graph edits

    # island 1: 7296
    ca_shp$adj <- add_edge(ca_shp$adj, 7296, 7300)

    # island 2: 3442 3443
    nbrs <- geomander::suggest_component_connection(ca_shp, ca_shp$adj)
    ca_shp$adj <- add_edge(ca_shp$adj, nbrs$x, nbrs$y)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ca_shp$adj, ca_shp$ssd_2020)
    ccm(ca_shp$adj, ca_shp$shd_2020)

    ca_shp <- ca_shp |>
        fix_geo_assignment(muni)

    write_rds(ca_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ca_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CA} shapefile")
}

# replace NA values with 0
ca_shp <- ca_shp |>
    mutate(
        across(where(is.numeric), \(x) coalesce(x, 0)
    ))
