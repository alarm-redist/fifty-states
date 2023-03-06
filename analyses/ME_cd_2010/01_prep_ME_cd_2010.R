###############################################################################
# Download and prepare data for `ME_cd_2010` analysis
# © ALARM Project, October 2022
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
cli_process_start("Downloading files for {.pkg ME_cd_2010}")

path_data <- download_redistricting_file("ME", "data-raw/ME", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/me_2010_congress_2011-09-28_2021-12-31.zip"
path_enacted <- "data-raw/ME/ME_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "ME_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/ME/ME_enacted/Maine_US_Congressional_Districts_2011_GeoLibrary.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ME_2010/shp_vtd.rds"
perim_path <- "data-out/ME_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ME} shapefile")
    # read in redistricting data
    me_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$ME)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("ME", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("ME"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("ME", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("ME"), vtd),
            cd_2000 = as.integer(cd))
    me_shp <- left_join(me_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf("ME", from = read_baf_cd113("ME"), year = 2010) %>%
        rename(GEOID = vtd) %>% mutate(GEOID = paste0("23", GEOID))
    me_shp <- me_shp %>%
        left_join(baf_cd113, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = me_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        me_shp <- rmapshaper::ms_simplify(me_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    me_shp$adj <- redist.adjacency(me_shp)

    # fix disconnected islands, respecting district assumptions
    adds <- suggest_component_connection(me_shp, me_shp$adj, me_shp$cd_2010)
    me_shp$adj <- me_shp$adj %>% add_edge(adds$x, adds$y)

    me_shp <- me_shp %>%
        fix_geo_assignment(muni)

    write_rds(me_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    me_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ME} shapefile")
}
