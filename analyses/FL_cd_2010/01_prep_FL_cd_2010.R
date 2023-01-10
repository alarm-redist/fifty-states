###############################################################################
# Download and prepare data for `FL_cd_2010` analysis
# © ALARM Project, December 2022
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
cli_process_start("Downloading files for {.pkg FL_cd_2010}")

path_data <- download_redistricting_file("FL", "data-raw/FL", year = 2010)

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/florida/>
url <- "https://redistricting.lls.edu/wp-content/uploads/fl_2010_congress_2012-04-30_2015-12-02.zip"
path_enacted <- "data-raw/FL/FL_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "FL_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/FL/FL_enacted/h000c9047.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/FL_2010/shp_vtd.rds"
perim_path <- "data-out/FL_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong FL} shapefile")
    # read in redistricting data
    fl_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$FL)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("FL", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("FL"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("FL", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("FL"), vtd),
            cd_2000 = as.integer(cd))
    fl_shp <- left_join(fl_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    fl_shp <- fl_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(fl_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = fl_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        fl_shp <- rmapshaper::ms_simplify(fl_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    fl_shp$adj <- redist.adjacency(fl_shp)

    # TODO any custom adjacency graph edits here

    fl_shp <- fl_shp %>%
        fix_geo_assignment(muni)

    fl_shp$adj <- fl_shp$adj %>% add_edge(suggest_neighbors(fl_shp, fl_shp$adj)$x, suggest_neighbors(fl_shp, fl_shp$adj)$y)

    write_rds(fl_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    fl_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong FL} shapefile")
}
