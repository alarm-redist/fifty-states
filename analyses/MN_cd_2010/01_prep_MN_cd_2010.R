###############################################################################
# Download and prepare data for `MN_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg MN_cd_2010}")

path_data <- download_redistricting_file("MN", "data-raw/MN", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/mn_2010_congress_2012-02-21_2021-12-31.zip"
path_enacted <- "data-raw/MN/MN_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "MN_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/MN/MN_enacted/C2012.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MN_2010/shp_vtd.rds"
perim_path <- "data-out/MN_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MN} shapefile")
    # read in redistricting data
    mn_shp <- read_csv(here(path_data), col_types = cols(GEOID10 = "c")) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$MN)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # Fix labeling
    mn_shp$state <- "MN"

    # add municipalities
    d_muni <- make_from_baf("MN", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("MN"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MN", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("MN"), vtd),
            cd_2000 = as.integer(cd))
    mn_shp <- left_join(mn_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    mn_shp <- mn_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(mn_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = mn_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mn_shp <- rmapshaper::ms_simplify(mn_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mn_shp$adj <- redist.adjacency(mn_shp)

    mn_shp <- mn_shp %>%
        fix_geo_assignment(muni)

    write_rds(mn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MN} shapefile")
}
