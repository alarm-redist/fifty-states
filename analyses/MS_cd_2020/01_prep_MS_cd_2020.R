###############################################################################
# Download and prepare data for `MS_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MS_cd_2020}")

path_data <- download_redistricting_file("MS", "data-raw/MS")

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/mississippi/>
# url <- "https://redistricting.lls.edu/wp-content/uploads/`state`_2020_congress_XXXXX.zip"
# path_enacted <- "data-raw/MS/MS_enacted.zip"
# download(url, here(path_enacted))
# unzip(here(path_enacted), exdir = here(dirname(path_enacted), "MS_enacted"))
# file.remove(path_enacted)
# path_enacted <- "data-raw/MS/MS_enacted/XXXXXXX.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MS_2020/shp_vtd.rds"
perim_path <- "data-out/MS_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MS} shapefile")
    # read in redistricting data
    # custom tabulation from NYT Upshot data
    state <- "MS"
    nyt <- geojsonsf::geojson_sf("data-raw/precincts-with-results.geojson") %>%
        mutate(state = str_sub(GEOID, 1, 2)) %>%
        filter(state == "28")

    block <- censable::build_dec("block", state, year = 2010)
    match_list <- geo_match(from = block, to = nyt, method = "area")
    elec_at_2010 <- tibble(GEOID = block$GEOID) %>%
        mutate(pre_20_rep_tru = estimate_down(value = nyt$votes_rep, wts = block[["vap"]], group = match_list),
            pre_20_dem_bid = estimate_down(value = nyt$votes_dem, wts = block[["vap"]], group = match_list)
        )

    vest_cw <- cvap::vest_crosswalk(state)
    rt <- PL94171::pl_retally(elec_at_2010, crosswalk = vest_cw)

    tract <- rt %>%
        censable::breakdown_geoid() %>%
        censable::construct_geoid("tract") %>%
        select(GEOID, starts_with("pre_")) %>%
        group_by(GEOID) %>%
        summarize(across(.fns = sum)) %>%
        mutate(ndv = pre_20_dem_bid, adv_20 = pre_20_dem_bid,
            nrv = pre_20_rep_tru, arv_20 = pre_20_rep_tru)

    ms_shp <- censable::build_dec("tract", state) %>%
        left_join(tract, by = "GEOID")
    ms_shp <- ms_shp %>%
        censable::breakdown_geoid() %>%
        mutate(state = "28")

    ms_shp <- ms_shp %>%
        st_transform(EPSG$MS)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- PL94171::pl_get_baf("MS")$INCPLACE_CDP %>%
        censable::breakdown_geoid("BLOCKID") %>%
        censable::construct_geoid("tract") %>%
        group_by(GEOID) %>%
        summarize(muni = Mode(PLACEFP))
    d_cd <- PL94171::pl_get_baf("MS")$CD %>%
        censable::breakdown_geoid("BLOCKID") %>%
        censable::construct_geoid("tract") %>%
        group_by(GEOID) %>%
        summarize(cd_2010 = Mode(DISTRICT))
    ms_shp <- left_join(ms_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    ms_shp <- ms_shp %>% filter(!st_is_empty(geometry))

    # add the enacted plan
    # cd_shp <- st_read(here(path_enacted))
    # ms_shp = ms_shp %>%
    #     mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
    #         geo_match(ms_shp, cd_shp, method = "area")],
    #         .after = cd_2010)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ms_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ms_shp <- rmapshaper::ms_simplify(ms_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ms_shp$adj <- redist.adjacency(ms_shp)

    ms_shp <- ms_shp %>%
        fix_geo_assignment(muni)

    write_rds(ms_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ms_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MS} shapefile")
}
