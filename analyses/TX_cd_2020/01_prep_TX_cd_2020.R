###############################################################################
# Download and prepare data for `TX_cd_2020` analysis
# © ALARM Project, February 2022
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(sf)
    library(tidyverse)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg TX_cd_2020}")

path_data <- download_redistricting_file("TX", "data-raw/TX")

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/tx_2020_congress_2021-10-25_2031-06-30.zip"
path_enacted <- "data-raw/TX/TX_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "TX_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/TX/TX_enacted/tx_2020_congress_2021-10-25_2031-06-30.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TX_2020/shp_vtd.rds"
perim_path <- "data-out/TX_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TX} shapefile")
    # read in redistricting data
    tx_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$TX)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("TX", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("TX"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("TX", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("TX"), vtd),
            cd_2010 = as.integer(cd))
    tx_shp <- left_join(tx_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- cd_shp %>% st_transform(4269)
    tx_shp <- tx_shp %>% st_transform(4269)

    tx_shp <- tx_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$District)[
            geo_match(tx_shp, cd_shp, method = "area")],
        .after = cd_2010)

    state <- "TX"
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

    cvap <- cvap %>% mutate(GEOID = paste0("48", GEOID))

    tx_shp <- tx_shp %>%
        left_join(cvap, by = "GEOID") %>%
        st_as_sf()

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = tx_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tx_shp <- rmapshaper::ms_simplify(tx_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    tx_shp$adj <- redist.adjacency(tx_shp)

    tx_shp <- tx_shp %>%
        fix_geo_assignment(muni)

    write_rds(tx_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tx_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TX} shapefile")
}

source("analyses/TX_cd_2020/TX_helpers.R")
