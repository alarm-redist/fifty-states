###############################################################################
# Download and prepare data for `NV_cd_2010` analysis
# © ALARM Project, September 2022
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
cli_process_start("Downloading files for {.pkg NV_cd_2010}")

path_data <- download_redistricting_file("NV", "data-raw/NV", year = 2010)

# Download the enacted plan
url <- "https://redistricting.lls.edu/wp-content/uploads/nv_2010_congress_2011-10-27_2021-12-31.zip"
path_enacted <- "data-raw/NV/NV_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NV_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/NV/NV_enacted/Congressional.shp"

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NV_2010/shp_vtd.rds"
perim_path <- "data-out/NV_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NV} shapefile")

    # Read in redistricting data
    nv_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$NV)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # Add municipalities
    d_muni <- make_from_baf("NV", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("NV"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NV", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("NV"), vtd),
            cd_2000 = as.integer(cd))
    nv_shp <- left_join(nv_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)


    # Add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    nv_shp <- nv_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District)[
            geo_match(nv_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    prep_perims(shp = nv_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # Simplify geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nv_shp <- rmapshaper::ms_simplify(nv_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # Create adjacency graph
    nv_shp$adj <- redist.adjacency(nv_shp)

    nv_shp <- nv_shp %>%
        fix_geo_assignment(muni)

    write_rds(nv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NV} shapefile")
}
