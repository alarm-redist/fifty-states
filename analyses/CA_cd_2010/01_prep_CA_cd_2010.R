###############################################################################
# Download and prepare data for `CA_cd_2010` analysis
# © ALARM Project, February 2023
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
cli_process_start("Downloading files for {.pkg CA_cd_2010}")

path_data <- download_redistricting_file("CA", "data-raw/CA", type = "block", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ca_2010_congress_2012-01-17_2021-12-31.zip"
path_enacted <- "data-raw/CA/CA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "CA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/CA/CA_enacted/viz_20110728_q2_cd_finaldraft_shp/20110727_q2_congressional_final_draft.shp"
path_dbf <- "data-raw/CA/CA_enacted/viz_20110728_q2_cd_finaldraft_shp/20110727_Q2_CONGRESSIONAL_FINAL_DRAFT.DBF"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_2010/shp_vtd.rds"
perim_path <- "data-out/CA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CA} shapefile")
    # read in redistricting data
    ca_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        left_join(y = tigris::blocks("CA", year = 2010), by = c("GEOID" = "GEOID10")) %>%
        st_as_sf() %>%
        st_transform(EPSG$CA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- get_baf_10("CA", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_cd <- get_baf_10("CA", "CD")[[1]] %>%
        rename(GEOID = BLOCKID, cd_2000 = DISTRICT)
    ca_shp <- left_join(ca_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    ca_shp <- ca_shp %>%
        as_tibble() %>%
        mutate(GEOID = str_sub(GEOID, 1, 11)) %>%
        group_by(GEOID) %>%
        summarize(cd_2000 = Mode(cd_2000),
            muni = Mode(muni),
            state = unique(state),
            county = unique(county),
            across(where(is.numeric), sum)
        ) %>%
        left_join(y = tinytiger::tt_tracts("CA", year = 2010) %>%
            select(GEOID = GEOID10), by = c("GEOID")) %>%
        st_as_sf() %>%
        st_transform(EPSG$CA)

    baf_cd113 <- read_baf_cd113("CA") %>%
        transmute(
            GEOID = str_sub(BLOCKID, 1, 11),
            cd_2010 = as.integer(cd_2010)
        ) %>%
        group_by(GEOID) %>%
        summarize(cd_2010 = Mode(cd_2010))
    ca_shp <- ca_shp %>%
        left_join(baf_cd113, by = "GEOID")
    ca_shp <- ca_shp  %>%
        relocate(cd_2010, .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ca_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ca_shp$adj <- redist.adjacency(ca_shp)

    # connect islands
    nbrs <- geomander::suggest_component_connection(ca_shp, ca_shp$adj)
    ca_shp$adj <- add_edge(ca_shp$adj, nbrs$x, nbrs$y)

    ca_shp$adj <- add_edge(ca_shp$adj, 6479, 6834)

    ca_shp <- ca_shp %>%
        fix_geo_assignment(muni)

    write_rds(ca_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ca_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CA} shapefile")
}
