###############################################################################
# Download and prepare data for `NM_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NM_cd_2020}")

path_data <- download_redistricting_file("NM", "data-raw/NM")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NM_2020/shp_vtd.rds"
perim_path <- "data-out/NM_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NM} shapefile")
    # read in redistricting data
    nm_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NM)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NM", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NM"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NM", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NM"), vtd),
            cd_2010 = as.integer(cd))
    nm_shp <- left_join(nm_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nm_shp,
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

