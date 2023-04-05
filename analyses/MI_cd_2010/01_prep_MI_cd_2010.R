###############################################################################
# Download and prepare data for `MI_cd_2010` analysis
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
cli_process_start("Downloading files for {.pkg MI_cd_2010}")

path_data <- download_redistricting_file("MI", "data-raw/MI", year = 2010, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MI_2010/shp_vtd.rds"
perim_path <- "data-out/MI_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MI} shapefile")
    # read in redistricting data
    mi_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$MI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    mi_shp <- mi_shp %>%
        filter(area_land >= area_water | pop > 0)

    # add municipalities
    d_muni <- make_from_baf("MI", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("MI"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MI", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("MI"), vtd),
                  cd_2000 = as.integer(cd))
    mi_shp <- left_join(mi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)


    # add the enacted plan
    baf_cd113 <- make_from_baf("MI", from = read_baf_cd113("MI"), year = 2010) %>%
        rename(GEOID = vtd) %>%
        mutate(GEOID = paste0("26", GEOID))

    mi_shp <- mi_shp %>%
        left_join(baf_cd113, by = "GEOID")

    mi_shp <- mi_shp %>%
        mutate(
            cd_2010 = as.integer(cd_2010)
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mi_shp,
                               perim_path = here(perim_path)) %>%
        invisible()

    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mi_shp <- rmapshaper::ms_simplify(mi_shp, keep = 0.05,
                                          keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mi_shp$adj <- redist.adjacency(mi_shp)

    for (i in which(is.na(mi_shp$cd_2010))) {
        mi_shp$cd_2010[i] <- Mode(mi_shp$cd_2010[mi_shp$adj[[i]] + 1])
    }

    #Check for missing connections
    if (FALSE) {
        redist.plot.adj(mi_shp, mi_shp$adj, centroids = F)
        x <- redist:::contiguity(mi_shp$adj, rep(1, length(mi_shp$adj)))
        unique(mi_shp$county[x > 1])

        idx <- which(x > 1 & str_detect(mi_shp$county, "097"))
        bbox <- st_bbox(st_buffer(mi_shp$geometry[idx], 800))
        lbls <- rep("", nrow(mi_shp))
        #adj_idxs <- c(idx, unlist(adj_nowater[idx]) + 1L)
        # adj_idxs = c(adj_idxs, unlist(adj_nowater[adj_idxs]) + 1L)
        lbls[idx] <- mi_shp$GEOID[idx]
        ggplot(mi_shp) +
            geom_sf(aes(fill = x > 1), size = 0.1) +
            geom_sf(data = d_water, size = 0.0, fill = "#ffffff55", color = NA) +
            coord_sf(xlim = bbox[c(1, 3)], ylim = bbox[c(2, 4)]) +
            geom_sf_text(aes(label = lbls), size = 2.5) +
            theme_void()

        table(redist:::contiguity(mi_shp$adj, mi_shp$cd_2010))
    }


    # manual connections
    add_update_edge <- function(vtd1, vtd2) {
        mi_shp$adj <<- add_edge(mi_shp$adj, which(mi_shp$GEOID == vtd1), which(mi_shp$GEOID == vtd2))
    }

    # Connect Charlevoix
    add_update_edge("26029029017", "26029029016")

    # Connect UP
    #add_update_edge("26047047022", "26097097010")

    # Connect UP attempt 2
    add_update_edge("26047000220", "26097000010")

    suggestions <- suggest_component_connection(mi_shp, mi_shp$adj)

    mi_shp$adj <- add_edge(mi_shp$adj, suggestions$x, suggestions$y)

    mi_shp <- mi_shp %>%
        fix_geo_assignment(muni)

    write_rds(mi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MI} shapefile")
}

