###############################################################################
# Download and prepare data for `RI_cd_2010` analysis
# © ALARM Project, January 2023
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
cli_process_start("Downloading files for {.pkg RI_cd_2010}")

path_data <- download_redistricting_file("RI", "data-raw/RI", type = 'block', year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ri_2010_congress_2012-02-08_2021-12-31.zip"
path_enacted <- "data-raw/RI/RI_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "RI_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/RI/RI_enacted/2a3f5ece-e912-4099-9a63-56417f74a25e202044-1-zjh6dc.92ezj.shp"

# download enacted state senate plan
url_ssd <- "https://redistricting.lls.edu/wp-content/uploads/ri_2010_state_upper_2012-02-08_2021-12-31.zip"
path_enacted_ssd <- "data-raw/RI/RI_enacted_ssd.zip"
download(url_ssd, here(path_enacted_ssd))
unzip(here(path_enacted_ssd), exdir = here(dirname(path_enacted_ssd), "RI_enacted_ssd"))
file.remove(path_enacted_ssd)
path_enacted_ssd <- "data-raw/RI/RI_enacted_ssd/Senate_Districts.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/RI_2010/shp_vtd.rds"
perim_path <- "data-out/RI_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong RI} shapefile")
    # read in redistricting block data
    ri_shp <- read_csv(path_data, col_types = cols(GEOID = "c")) %>%
        left_join(y = tigris::blocks("RI", year = 2010), by = c("GEOID" = "GEOID10")) %>%
        st_as_sf() %>%
        st_transform(EPSG$RI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    place_shp <- tinytiger::tt_places("RI", year = 2010)
    matches_muni <- geomander::geo_match(from = ri_shp, to = place_shp, tiebreaker = FALSE)
    matches_muni[matches_muni < 0] <- NA
    d_muni <- tibble(GEOID = ri_shp$GEOID, muni = place_shp$PLACENS10[matches_muni])

    d_cd <- get_baf_10(state = "RI", "CD")[[1]]  %>%
        transmute(
            GEOID = BLOCKID,
            cd_2000 = as.integer(DISTRICT)
            )

    ri_shp <- left_join(ri_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    ri_shp <- ri_shp %>%
        as_tibble() %>%
        mutate(GEOID = str_sub(GEOID, 1, 11)) %>%
        group_by(GEOID) %>%
        summarize(
            state = state[1],
            county = county[1],
            muni = Mode(muni),
            cd_2000 = Mode(cd_2000),
            across(where(is.numeric), sum)
        ) %>%
        left_join(y = tinytiger::tt_tracts("RI", year = 2010) %>%
                      select(GEOID = GEOID10),
                  by = c("GEOID")) %>%
        st_as_sf() %>%
        st_transform(EPSG$RI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add the enacted plan
    baf_cd113 <- read_baf_cd113("RI") %>%
        transmute(
            GEOID = str_sub(BLOCKID, 1, 11),
            cd_2010 = as.integer(cd_2010)
            ) %>%
        group_by(GEOID) %>%
        summarize(cd_2010 = Mode(cd_2010))
    ri_shp <- ri_shp %>%
        left_join(baf_cd113, by = "GEOID")

    # add state senate districts
    ssd_shp <- st_read(here(path_enacted_ssd))
    ri_shp <- ri_shp %>%
        mutate(ssd_2010 = as.integer(ssd_shp$SLDUST)[
            geo_match(ri_shp, ssd_shp, method = "area")],
            .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ri_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ri_shp <- rmapshaper::ms_simplify(ri_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ri_shp$adj <- redist.adjacency(ri_shp)

    # fix contiguity
    # add Judith Point - Block Island ferry
    ri_shp$adj <- add_edge(ri_shp$adj, 243, 244)

    ri_shp <- ri_shp %>%
        fix_geo_assignment(muni)

    write_rds(ri_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ri_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong RI} shapefile")
}
