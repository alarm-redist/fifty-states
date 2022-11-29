###############################################################################
# Download and prepare data for `WI_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg WI_cd_2010}")

path_data <- download_redistricting_file("WI", "data-raw/WI", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/wi_2010_congress_2011-08-09_2021-12-31.zip"
path_enacted <- "data-raw/WI/WI_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "WI_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/WI/WI_enacted/Wisconsin_Congressional_Districts_2011.shp"

# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WI_2010/shp_vtd.rds"
perim_path <- "data-out/WI_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WI} shapefile")
    # read in redistricting data
    wi_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$WI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WI", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("WI"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("WI", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("WI"), vtd),
            cd_2000 = as.integer(cd))
    wi_shp <- left_join(wi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    wi_shp <- wi_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_N)[
            geo_match(wi_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wi_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wi_shp <- rmapshaper::ms_simplify(wi_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wi_shp$adj <- redist.adjacency(wi_shp)

    wi_shp <- wi_shp %>%
        fix_geo_assignment(muni)

    write_rds(wi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WI} shapefile")
}
