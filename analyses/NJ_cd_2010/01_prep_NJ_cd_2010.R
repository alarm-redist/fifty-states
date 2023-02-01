###############################################################################
# Download and prepare data for `NJ_cd_2010` analysis
# © ALARM Project, January 2023
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
cli_process_start("Downloading files for {.pkg NJ_cd_2010}")

path_data <- download_redistricting_file("NJ", "data-raw/NJ", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/nj_2010_congress_2011-12-23_2021-12-31.zip"
path_enacted <- "data-raw/NJ/NJ_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NJ_enacted"))
file.remove(path_enacted)

path_enacted <- "data-raw/NJ/NJ_enacted/NJCD_2011_PLAN_SHAPE_FILE.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NJ_2010/shp_vtd.rds"
perim_path <- "data-out/NJ_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NJ} shapefile")
    # read in redistricting data
    nj_shp <- read_csv(here(path_data), col_types = cols(GEOID10 = "c")) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$NJ)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NJ", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("NJ"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NJ", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("NJ"), vtd),
            cd_2000 = as.integer(cd))
    nj_shp <- left_join(nj_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    nj_shp <- nj_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(nj_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # fix labeling
    nj_shp$state <- "NJ"

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nj_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nj_shp <- rmapshaper::ms_simplify(nj_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nj_shp$adj <- redist.adjacency(nj_shp)

    nj_shp <- nj_shp %>%
        fix_geo_assignment(muni)

    write_rds(nj_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nj_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NJ} shapefile")
}
