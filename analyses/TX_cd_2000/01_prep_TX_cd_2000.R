###############################################################################
# Download and prepare data for `TX_cd_2000` analysis
# © ALARM Project, August 2025
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(baf)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg TX_cd_2000}")

path_data <- download_redistricting_file("TX", "data-raw/TX", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TX_2000/shp_vtd.rds"
perim_path <- "data-out/TX_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TX} shapefile")
    # read in redistricting data
    tx_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$TX)

    tx_shp <- tx_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Add CVAP total and CVAP hispanic counts
    path_cvap <- here(paste0("data-raw/", state, "/cvap.rds"))

    if (!file.exists(path_cvap)) {
        bg <- readRDS("data-raw/TX/blockgr_2000.rds")
        blks <- censable::build_dec(geography = "block", year = 2000, state = "TX", geometry = FALSE)
        cvap <- cvap::cvap_distribute(bg, blks, wts = "vap")
        vtd_baf <- read_csv("data-raw/TX/BlockAssign_ST48_TX_VTD.txt", col_types = "ccc")

        cvap <- cvap %>%
            left_join(vtd_baf %>% rename(GEOID = BLOCKID),
                by = "GEOID")

        cvap <- cvap %>%
            mutate(GEOID = paste0(COUNTYFP, "00", DISTRICT)) %>%
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
    redistmetrics::prep_perims(shp = tx_shp,
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
