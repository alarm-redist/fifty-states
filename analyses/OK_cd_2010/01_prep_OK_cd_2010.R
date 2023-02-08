###############################################################################
# Download and prepare data for `OK_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg OK_cd_2010}")

path_data <- download_redistricting_file("OK", "data-raw/OK", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ok_2010_congress_2011-05-10_2021-12-31.zip"
path_enacted <- "data-raw/OK/OK_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "OK_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/OK/OK_enacted/HB1527 - OK Congressional Districts.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OK_2010/shp_vtd.rds"
perim_path <- "data-out/OK_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OK} shapefile")
    # read in redistricting data
    ok_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$OK)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("OK", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("OK"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("OK", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("OK"), vtd),
            cd_2000 = as.integer(cd))
    ok_shp <- left_join(ok_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    ok_shp <- ok_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_N)[
            geo_match(ok_shp, cd_shp, method = "area")],
        .after = cd_2000)


    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ok_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ok_shp <- rmapshaper::ms_simplify(ok_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ok_shp$adj <- redist.adjacency(ok_shp)

    ok_shp <- ok_shp %>%
        fix_geo_assignment(muni)

    write_rds(ok_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ok_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OK} shapefile")
}
