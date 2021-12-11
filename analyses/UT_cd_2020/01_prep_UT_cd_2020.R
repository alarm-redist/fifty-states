###############################################################################
# Download and prepare data for `UT_cd_2020` analysis
# © ALARM Project, October 2021
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
cli_process_start("Downloading files for {.pkg UT_cd_2020}")

path_data <- download_redistricting_file("UT", "data-raw/UT")

url <- "https://citygate.utleg.gov/legdistricting/html/shapefiles/50153c8e438cbcb0eec55f2f59edc45c-output/50153c8e438cbcb0eec55f2f59edc45c.zip"
path_enacted <- "data-raw/UT/UT_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "UT_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/UT/UT_enacted/50153c8e438cbcb0eec55f2f59edc45c.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/UT_2020/shp_vtd.rds"
perim_path <- "data-out/UT_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong UT} shapefile")
    # read in redistricting data
    ut_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$UT)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("UT", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("UT"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("UT", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("UT"), vtd),
            cd_2010 = as.integer(cd))
    ut_shp <- left_join(ut_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add newly enacted plans
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- st_transform(cd_shp, crs = st_crs(ut_shp))
    ut_shp <- mutate(ut_shp,
        cd_2020 = geo_match(ut_shp, cd_shp, method = "area"),
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ut_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ut_shp <- rmapshaper::ms_simplify(ut_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ut_shp$adj <- redist.adjacency(ut_shp)

    ut_shp <- ut_shp %>%
        fix_geo_assignment(muni)

    write_rds(ut_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ut_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong UT} shapefile")
}
