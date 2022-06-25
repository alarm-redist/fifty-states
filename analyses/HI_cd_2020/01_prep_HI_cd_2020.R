###############################################################################
# Download and prepare data for `HI_cd_2020` analysis
# © ALARM Project, January 2022
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
cli_process_start("Downloading files for {.pkg HI_cd_2020}")

path_data <- download_redistricting_file("HI", "data-raw/HI", type = "block")

# download the enacted plan
path_enacted <- "data-raw/HI/HI_enacted.txt"
if (!file.exists(path_enacted)) {
    download("https://elections.hawaii.gov/wp-content/uploads/Congressional_Final_2022.txt",
        path_enacted)
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/HI_2020/shp_vtd.rds"
perim_path <- "data-out/HI_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong HI} shapefile")
    # read in redistricting data
    hi_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        left_join(y = tigris::blocks("HI", year = 2020), by  = "GEOID20") %>%
        st_as_sf() %>%
        st_transform(EPSG$HI) %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- PL94171::pl_get_baf("HI", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_cd <- PL94171::pl_get_baf("HI", "CD")[[1]]  %>%
        transmute(GEOID = BLOCKID,
            cd_2010 = as.integer(DISTRICT))
    hi_shp <- left_join(hi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)


    # add the enacted plan
    cd_baf <- read_csv(path_enacted, col_names = c("GEOID", "cd_2020"),
        col_types = c("ci"))

    hi_shp <- hi_shp %>%
        left_join(cd_baf, by = "GEOID") %>%
        mutate(tract = str_sub(GEOID, 1, 11)) %>%
        group_by(tract) %>%
        summarize(cd_2010 = Mode(cd_2010),
            cd_2020 = Mode(cd_2020),
            muni = Mode(muni),
            state = unique(state),
            county = unique(county),
            across(where(is.numeric), sum)
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = hi_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        hi_shp <- rmapshaper::ms_simplify(hi_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    hi_shp$adj <- redist.adjacency(hi_shp)

    # Connect islands, but not for use
    islands <- tribble(
        ~v1, ~v2,
        379, 413,
        413, 412,
        412, 411,
        411, 390,
        390, 459,
        459, 461,
        461, 460,
        460, 55
    )

    hi_shp$adj <- hi_shp$adj %>% add_edge(islands$v1, islands$v2)

    hi_shp <- hi_shp %>%
        fix_geo_assignment(muni)

    write_rds(hi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    hi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong HI} shapefile")
}
