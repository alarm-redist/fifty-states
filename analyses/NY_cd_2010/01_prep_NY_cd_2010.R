###############################################################################
# Download and prepare data for `NY_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg NY_cd_2010}")

path_data <- download_redistricting_file("NY", "data-raw/NY", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ny_2010_congress_2012-03-19_2021-12-31.zip"
path_enacted <- "data-raw/NY/NY_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NY_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/NY/NY_enacted/2012_Congress.shp" # TODO use actual SHP

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NY_2010/shp_vtd.rds"
perim_path <- "data-out/NY_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NY} shapefile")
    # read in redistricting data
    ny_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$NY)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NY", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("NY"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NY", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("NY"), vtd),
            cd_2000 = as.integer(cd))
    ny_shp <- left_join(ny_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    ny_shp <- ny_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(ny_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ny_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ny_shp <- rmapshaper::ms_simplify(ny_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    ny_shp <- st_make_valid(ny_shp)

    # create adjacency graph
    ny_shp$adj <- redist.adjacency(ny_shp)

    ny_shp <- ny_shp %>%
        fix_geo_assignment(muni)

    write_rds(ny_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ny_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NY} shapefile")
}
