###############################################################################
# Download and prepare data for `HI_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg HI_cd_2010}")

path_data <- download_redistricting_file("HI", "data-raw/HI", year = 2010, type = "block", overwrite = TRUE)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/hi_2010_congress_2011-09-26_2021-12-31.zip"
path_enacted <- "data-raw/HI/HI_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "HI_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/HI/HI_enacted/congress11.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/HI_2010/shp_vtd.rds"
perim_path <- "data-out/HI_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong HI} shapefile")
    # read in redistricting data
    hi_shp <- read_csv(here(path_data)) %>%
        mutate(GEOID = as.character(GEOID)) %>%
        left_join(y = tigris::blocks("HI", year = 2010), by  = c("GEOID" = "GEOID10")) %>%
        st_as_sf() %>%
        st_transform(EPSG$HI) %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- get_baf_10("HI", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_cd <- get_baf_10("HI", "CD")[[1]] %>%
        rename(GEOID = BLOCKID, cd_2000 = DISTRICT)
    hi_shp <- left_join(hi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan by geomatching Honolulu County
    # (the rest of the state is in District 2)
    cd_shp <- st_read(here(path_enacted))
    honolulu <- hi_shp %>% filter(county == "003") %>%
        mutate(cd_2010 = as.integer(cd_shp$USDist)[
            geo_match(honolulu, cd_shp, method = "area")],
            .after = cd_2000)
    rest_shp <- hi_shp %>%
        filter(county != "003") %>%
        mutate(cd_2010 = 2, .after = cd_2000)
    hi_shp <- rbind(rest_shp, honolulu)

    # group from block-level to tract-level

    hi_shp <- hi_shp %>%
        mutate(tract = str_sub(GEOID, 1, 11)) %>%
        group_by(tract) %>%
        summarize(cd_2000 = Mode(cd_2000),
                  cd_2010 = Mode(cd_2010),
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

    # Link islands

    island_codes <- tribble(
        ~v1, ~v2,
        "15001021800", "15009030100",
        "15009030303", "15003980000",
        "15009031503", "15009031601",
        "15009031601", "15009031700",
        "15009031801", "15003000110",
        "15003009904", "15007040500",
        "15007040900", "15007041200",
        "15007041200", "15003981200"
    )

    island_codes$v1 <- which(hi_shp$tract %in% island_codes$v1)[order(na.omit(match(hi_shp$tract, island_codes$v1)))]
    island_codes$v2 <- which(hi_shp$tract %in% island_codes$v2)[order(na.omit(match(hi_shp$tract, island_codes$v2)))]

    hi_shp$adj <- hi_shp$adj %>% add_edge(island_codes$v1, island_codes$v2, zero = TRUE)

    hi_shp <- hi_shp %>%
        fix_geo_assignment(muni)

    write_rds(hi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    hi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong HI} shapefile")
}
