###############################################################################
# Download and prepare data for `SC_cd_2010` analysis
# © ALARM Project, June 2022
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
cli_process_start("Downloading files for {.pkg SC_cd_2010}")

path_data <- download_redistricting_file("SC", "data-raw/SC", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/sc_2010_congress_2011-10-28_2021-12-31.zip"
path_enacted <- "data-raw/SC/SC_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "SC_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/SC/SC_enacted/H3992.shp"

# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/SC_2010/shp_vtd.rds"
perim_path <- "data-out/SC_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong SC} shapefile")
    # read in redistricting data
    sc_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$SC)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("SC", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("SC"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("SC", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("SC"), vtd),
            cd_2000 = as.integer(cd))
    sc_shp <- left_join(sc_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add missing ndv data
    sc_shp <- sc_shp %>%
        mutate(nrv = rowMeans(select(as_tibble(.), contains("_rep_")), na.rm = TRUE),
            ndv = rowMeans(select(as_tibble(.), contains("_dem_")), na.rm = TRUE))

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    sc_shp <- sc_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District)[
            geo_match(sc_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = sc_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        sc_shp <- rmapshaper::ms_simplify(sc_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    sc_shp$adj <- redist.adjacency(sc_shp)


    sc_shp <- sc_shp %>%
        fix_geo_assignment(muni)

    write_rds(sc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    sc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong SC} shapefile")
}
