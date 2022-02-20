###############################################################################
# Download and prepare data for `NM_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NM_cd_2020}")

path_data <- download_redistricting_file("NM", "data-raw/NM")

# download the enacted plan.
url <- "https://www.nmlegis.gov/Redistricting2021/221711.1/CD_221711_shapefile.zip"
path_enacted <- "data-raw/NM/NM_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NM_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/NM/NM_enacted/CD_221711_Shapefile.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NM_2020/shp_vtd.rds"
perim_path <- "data-out/NM_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NM} shapefile")
    # read in redistricting data
    nm_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NM)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NM", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NM"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NM", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NM"), vtd),
            cd_2010 = as.integer(cd))
    nm_shp <- left_join(nm_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- cd_shp %>%
        st_transform(EPSG$NM) %>%
        st_make_valid()
    nm_shp <- nm_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(nm_shp, cd_shp, method = "area")],
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nm_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nm_shp <- rmapshaper::ms_simplify(nm_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nm_shp$adj <- redist.adjacency(nm_shp)

    nm_shp <- nm_shp %>%
        fix_geo_assignment(muni)

    write_rds(nm_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nm_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NM} shapefile")
}
