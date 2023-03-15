###############################################################################
# Download and prepare data for `AR_cd_2010` analysis
# © ALARM Project, November 2022
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
cli_process_start("Downloading files for {.pkg AR_cd_2010}")

path_data <- download_redistricting_file("AR", "data-raw/AR", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ar_2010_congress_2011-04-14_2021-12-31.zip"
path_enacted <- "data-raw/AR/AR_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "AR_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/AR/AR_enacted/ADMIN_CONGRESSIONAL_DISTRICTS_polygon.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AR_2010/shp_vtd.rds"
perim_path <- "data-out/AR_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AR} shapefile")
    # read in redistricting data
    ar_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$AR)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("AR", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("AR"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("AR", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("AR"), vtd),
            cd_2000 = as.integer(cd))
    ar_shp <- left_join(ar_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf("AR", from = read_baf_cd113("AR"), year = 2010) %>%
        rename(GEOID = vtd) %>% mutate(GEOID = paste0("05", GEOID))
    ar_shp <- ar_shp %>%
        left_join(baf_cd113, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ar_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ar_shp <- rmapshaper::ms_simplify(ar_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ar_shp$adj <- redist.adjacency(st_make_valid(ar_shp))

    ar_shp <- ar_shp %>%
        fix_geo_assignment(muni)

    write_rds(ar_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ar_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AR} shapefile")
}
