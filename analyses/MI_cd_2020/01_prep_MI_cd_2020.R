###############################################################################
# Download and prepare data for `MI_cd_2020` analysis
# © ALARM Project, October 2021
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
cli_process_start("Downloading files for {.pkg MI_cd_2020}")

path_data <- download_redistricting_file("MI", "data-raw/MI")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MI_2020/shp_vtd.rds"
perim_path <- "data-out/MI_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MI} shapefile")
    # read in redistricting data
    mi_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    mi_shp <- mi_shp %>%
        filter(area_land >= area_water | pop > 0)

    # add municipalities
    d_muni <- make_from_baf("MI", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MI"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MI", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MI"), vtd),
            cd_2010 = as.integer(cd)) %>%
        suppressWarnings()
    mi_shp <- left_join(mi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = mi_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mi_shp <- rmapshaper::ms_simplify(mi_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mi_shp$adj <- redist.adjacency(mi_shp) %>%
        suppressWarnings()

    # helper plots to zoom in for manual connections
    if (FALSE) {
        filter(mi_shp, str_detect(county, "Mackinac") | str_detect(county, "Emmet")) %>%
            ggplot(aes(label = GEOID, fill = vtd)) +
            geom_sf(size = 0.3) +
            geom_sf_label(size = 2.3) +
            guides(fill = "none") +
            theme_void()
        ggplot(mi_shp, aes(fill = county)) +
            geom_sf(size = 0.3) +
            guides(fill = "none") +
            theme_void()
    }

    # Keweenaw (Isle Royale) already connected

    # Connect Charlevoix
    idx_1 <- which(mi_shp$GEOID == "26029029017")
    idx_2 <- which(mi_shp$GEOID == "26029029016")
    mi_shp$adj <- add_edge(mi_shp$adj, idx_1, idx_2)

    # Connect UP
    idx_1 <- which(mi_shp$GEOID == "26047047022")
    idx_2 <- which(mi_shp$GEOID == "26097097010")
    mi_shp$adj <- add_edge(mi_shp$adj, idx_1, idx_2)

    mi_shp <- mi_shp %>%
        fix_geo_assignment(muni)

    write_rds(mi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MI} shapefile")
}
