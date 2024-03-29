###############################################################################
# Download and prepare data for `FL_cd_2020` analysis
# © ALARM Project, March 2022
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
cli_process_start("Downloading files for {.pkg FL_cd_2020}")

path_data <- download_redistricting_file("FL", "data-raw/FL")

# download the enacted plan.
# plan had to be manually downloaded from: https://davesredistricting.org/maps#viewmap::27ce8314-c3a6-4365-b980-36d869398235
path_enacted <- "data-raw/FL/FL_enacted/POLYGON.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/FL_2020/shp_vtd.rds"
perim_path <- "data-out/FL_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong FL} shapefile")
    # read in redistricting data
    fl_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$FL)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("FL", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("FL"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("FL", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("FL"), vtd),
            cd_2010 = as.integer(cd))
    fl_shp <- left_join(fl_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- cd_shp %>%
        st_transform(EPSG$FL) %>%
        st_make_valid()
    fl_shp <- fl_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(fl_shp, cd_shp, method = "area")],
        .after = cd_2010)

    # get CVAP
    key <- "CENSUS API KEY" # Input own Census API Key
    tidycensus::census_api_key(key)
    state <- "FL"
    path_cvap <- here(paste0("data-raw/", state, "/cvap.rds"))

    if (!file.exists(path_cvap)) {
        cvap <-
            cvap::cvap_distribute_censable(state) %>% select(GEOID, starts_with("cvap"))
        vest_cw <- cvap::vest_crosswalk(state)
        cvap <-
            PL94171::pl_retally(cvap, crosswalk = vest_cw)
        vtd_baf <- PL94171::pl_get_baf(state)$VTD
        cvap <- cvap %>%
            left_join(vtd_baf %>% rename(GEOID = BLOCKID),
                by = "GEOID")
        cvap <- cvap %>%
            mutate(GEOID = paste0(COUNTYFP, DISTRICT)) %>%
            select(GEOID, starts_with("cvap"))
        cvap <- cvap %>%
            group_by(GEOID) %>%
            summarize(across(.fns = sum))
        saveRDS(cvap, path_cvap, compress = "xz")
    } else {
        cvap <- read_rds(path_cvap)
    }

    cvap <- cvap %>% mutate(GEOID = paste0("12", GEOID))

    fl_shp <- fl_shp %>%
        left_join(cvap, by = "GEOID") %>%
        st_as_sf()

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = fl_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        fl_shp <- rmapshaper::ms_simplify(fl_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    fl_shp$adj <- redist.adjacency(fl_shp)

    fl_shp <- fl_shp %>%
        fix_geo_assignment(muni)

    write_rds(fl_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    fl_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong FL} shapefile")
}
