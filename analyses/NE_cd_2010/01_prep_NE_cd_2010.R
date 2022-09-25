###############################################################################
# Download and prepare data for `NE_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg NE_cd_2010}")

path_data <- download_redistricting_file("NE", "data-raw/NE", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ne_2010_congress_2011-05-26_2021-12-31.zip"
path_enacted <- "data-raw/NE/NE_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NE_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/NE/NE_enacted/US_Congressional_Boundary.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NE_2010/shp_vtd.rds"
perim_path <- "data-out/NE_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NE} shapefile")
    # read in redistricting data
    ne_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$NE)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NE", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("NE"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NE", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("NE"), vtd),
            cd_2000 = as.integer(cd))
    ne_shp <- left_join(ne_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    ne_shp <- ne_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_1)[
            geo_match(ne_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ne_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ne_shp <- rmapshaper::ms_simplify(ne_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ne_shp$adj <- redist.adjacency(ne_shp)

    ne_shp <- ne_shp %>%
        fix_geo_assignment(muni)

    write_rds(ne_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ne_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NE} shapefile")
}
