###############################################################################
# Download and prepare data for `IN_cd_2020` analysis
# © ALARM Project, December 2021
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
cli_process_start("Downloading files for {.pkg IN_cd_2020}")

path_data <- download_redistricting_file("IN", "data-raw/IN")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/IN_2020/shp_vtd.rds"
perim_path <- "data-out/IN_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong IN} shapefile")
    # read in redistricting data
    in_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$IN)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("IN", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("IN"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("IN", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("IN"), vtd),
            cd_2010 = as.integer(cd))
    in_shp <- left_join(in_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add enacted ----
    dists <- read_sf("https://redistrict2020.org/files/IN-2021-09/Proposed_Indiana_Congressional_Districts.geojson")

    in_shp$cd_2020 <- geo_match(in_shp, dists, "area")

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = in_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        in_shp <- rmapshaper::ms_simplify(in_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    in_shp$adj <- redist.adjacency(in_shp)
    # 4096 is split, this keeps contiguity
    in_shp$cd_2020[4096] <- in_shp$cd_2020[4092]
    in_shp <- in_shp %>%
        fix_geo_assignment(muni)

    write_rds(in_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    in_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong IN} shapefile")
}
