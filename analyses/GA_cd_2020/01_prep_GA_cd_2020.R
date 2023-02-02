###############################################################################
# Download and prepare data for `GA_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg GA_cd_2020}")

path_data <- download_redistricting_file("GA", "data-raw/GA")

url <- "https://www.legis.ga.gov/api/document/docs/default-source/reapportionment-document-library/congress/congress-prop1-2021-shape.zip?sfvrsn=2045df27_2"
path_enacted <- "data-raw/GA/GA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "GA_enacted"))
path_enacted <- "data-raw/GA/GA_enacted/CONGRESS-PROP1-2021-shape.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/GA_2020/shp_vtd.rds"
perim_path <- "data-out/GA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong GA} shapefile")
    # read in redistricting data
    ga_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$GA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("GA", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("GA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("GA", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("GA"), vtd),
            cd_2010 = as.integer(cd))
    ga_shp <- left_join(ga_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add 2020 enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- st_transform(cd_shp, crs = st_crs(ga_shp)) %>%
        arrange(DISTRICT)
    ga_shp <- mutate(ga_shp,
                     cd_2020 = geo_match(ga_shp, cd_shp, method = "area"),
                     .after = cd_2010)

    # Create perimeters in case shapes are simplified
    prep_perims(shp = ga_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ga_shp <- rmapshaper::ms_simplify(ga_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ga_shp$adj <- redist.adjacency(ga_shp)

    ga_shp <- ga_shp %>%
        fix_geo_assignment(muni)

    write_rds(ga_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ga_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong GA} shapefile")
}
