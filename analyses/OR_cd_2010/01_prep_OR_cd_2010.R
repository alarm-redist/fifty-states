###############################################################################
# Download and prepare data for `OR_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg OR_cd_2010}")

path_data <- download_redistricting_file("OR", "data-raw/OR", year = 2010, type = "block")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OR_2010/shp_vtd.rds"
perim_path <- "data-out/OR_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OR} shapefile")
    # read in redistricting data
    or_shp <- read_csv(path_data, col_types = cols(GEOID = "c")) %>%
        left_join(y = tinytiger::tt_blocks("OR", year = 2010), by = c("GEOID" = "GEOID10")) %>%
        st_as_sf() %>%
        st_transform(EPSG$OR)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- get_baf_10("OR")$INCPLACE_CDP  %>%
        transmute(
            GEOID = BLOCKID,
            muni = PLACEFP
        )
    d_cd <- get_baf_10("OR")$CD  %>%
        transmute(
            GEOID = BLOCKID,
            cd_2000 = DISTRICT
        )
    or_shp <- left_join(or_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- read_baf_cd113("OR") %>%
        rename(GEOID = BLOCKID)
    or_shp <- or_shp %>%
        left_join(baf_cd113, by = "GEOID")

    or_shp <- or_shp %>%
        as_tibble() %>%
        mutate(GEOID = str_sub(GEOID, 1, 11)) %>%
        group_by(GEOID) %>%
        summarize(
            state = state[1],
            county = county[1],
            muni = Mode(muni),
            cd_2000 = Mode(cd_2000),
            cd_2010 = Mode(cd_2010),
            across(where(is.numeric), sum)
        ) %>%
        left_join(y = tinytiger::tt_tracts("OR", year = 2010) %>%
                      select(GEOID = GEOID10),
                  by = c("GEOID")) %>%
        st_as_sf() %>%
        st_transform(EPSG$OR)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = or_shp,
                               perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        or_shp <- rmapshaper::ms_simplify(or_shp, keep = 0.05,
                                          keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    or_shp$adj <- redist.adjacency(or_shp)

    disconn_cty <- function(adj, cty1, cty2) {
        v1 <- which(or_shp$county == str_c(cty1, " County"))
        if (length(v1) == 0) stop(cty1, "not found")
        v2 <- which(or_shp$county == str_c(cty2, " County"))
        if (length(v2) == 0) stop(cty1, "not found")
        vs <- tidyr::crossing(v1, v2)
        remove_edge(adj, vs$v1, vs$v2)
    }
    or_shp$adj <- or_shp$adj %>%
        disconn_cty("Curry", "Josephine") %>%
        disconn_cty("Benton", "Lane") %>%
        disconn_cty("Polk", "Lincoln") %>%
        disconn_cty("Marion", "Jefferson") %>%
        disconn_cty("Marion", "Wasco") %>%
        disconn_cty("Wallowa", "Baker") %>%
        disconn_cty("Morrow", "Grant") %>%
        disconn_cty("Crook", "Grant") %>%
        disconn_cty("Deschutes", "Harney") %>%
        disconn_cty("Deschutes", "Linn")

    or_shp <- or_shp %>%
        fix_geo_assignment(muni)

    write_rds(or_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    or_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OR} shapefile")
}
