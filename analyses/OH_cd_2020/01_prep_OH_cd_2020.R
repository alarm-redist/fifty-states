###############################################################################
# Download and prepare data for `OH_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg OH_cd_2020}")

path_data <- download_redistricting_file("OH", "data-raw/OH")

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/oh_2020_congress_2022-02-19_2024-12-31.zip"
path_enacted <- "data-raw/OH/OH_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "OH_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/OH/OH_enacted/oh_2020_congress_2021-11-20_2024-12-31.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OH_2020/shp_vtd.rds"
perim_path <- "data-out/OH_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OH} shapefile")
    # read in redistricting data
    oh_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$OH)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("OH", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("OH"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("OH", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("OH"), vtd),
            cd_2010 = as.integer(cd))
    oh_shp <- left_join(oh_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted)) %>%
        st_transform(st_crs(oh_shp))
    oh_shp <- oh_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$Districts)[
            geo_match(oh_shp, cd_shp, method = "area")],
        .after = cd_2010)

    water_precs <- "39(093|035|007|085)ZZZZZZ"
    oh_shp <- filter(oh_shp, !str_starts(GEOID, water_precs))

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = oh_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        oh_shp <- rmapshaper::ms_simplify(oh_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    oh_shp$adj <- redist.adjacency(oh_shp)

    oh_shp <- oh_shp %>%
        fix_geo_assignment(muni)

    write_rds(oh_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    oh_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OH} shapefile")
}
